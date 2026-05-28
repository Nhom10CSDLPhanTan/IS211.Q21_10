import argparse
import json
import logging
import os
import sys

from pyspark.sql import SparkSession


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    stream=sys.stdout,
)


def required_env(name: str) -> str:
    value = os.environ.get(name)

    if value is None or value == "":
        raise ValueError(f"Missing required environment variable: {name}")

    return value


def to_int(value) -> int:
    if value is None:
        return 0
    return int(float(value))


def choose_num_partitions(row_count: int) -> int:
    if row_count <= 50_000:
        return 1
    elif row_count <= 500_000:
        return 4
    elif row_count <= 2_000_000:
        return 8
    else:
        return 12


def detect_bounds(
    spark,
    oracle_jdbc_url,
    oracle_user,
    oracle_password,
    source_table,
    partition_column,
):
    bounds_query = f"""
        (
            SELECT
                MIN({partition_column}) AS lower_bound,
                MAX({partition_column}) AS upper_bound,
                COUNT(*) AS row_count
            FROM {source_table}
        ) bounds
    """

    bounds_df = (
        spark.read
        .format("jdbc")
        .option("url", oracle_jdbc_url)
        .option("user", oracle_user)
        .option("password", oracle_password)
        .option("driver", "oracle.jdbc.OracleDriver")
        .option("dbtable", bounds_query)
        .load()
    )

    bounds = bounds_df.collect()[0]

    lower_bound = to_int(bounds["LOWER_BOUND"])
    upper_bound = to_int(bounds["UPPER_BOUND"])
    row_count = to_int(bounds["ROW_COUNT"])

    return lower_bound, upper_bound, row_count


def sync_one_table(
    spark,
    table_config,
    oracle_jdbc_url,
    oracle_user,
    oracle_password,
    cockroach_jdbc_url,
    cockroach_user,
    cockroach_password,
):
    source_table = table_config["source_table"]
    target_table = table_config["target_table"]
    columns = table_config["columns"]

    partition_column = table_config.get("partition_column")
    lower_bound = table_config.get("lower_bound")
    upper_bound = table_config.get("upper_bound")
    num_partitions = table_config.get("num_partitions")

    logging.info("==================================================")
    logging.info("Start syncing %s -> %s", source_table, target_table)

    if partition_column and (
        lower_bound is None or upper_bound is None or num_partitions is None
    ):
        logging.info(
            "Auto detecting bounds for %s using partition column %s",
            source_table,
            partition_column,
        )

        lower_bound, upper_bound, row_count = detect_bounds(
            spark=spark,
            oracle_jdbc_url=oracle_jdbc_url,
            oracle_user=oracle_user,
            oracle_password=oracle_password,
            source_table=source_table,
            partition_column=partition_column,
        )

        if row_count == 0:
            logging.warning("Source table %s has no rows. Skip.", source_table)
            return

        num_partitions = choose_num_partitions(row_count)

        logging.info(
            "Detected bounds: lower=%s, upper=%s, rows=%s, partitions=%s",
            lower_bound,
            upper_bound,
            row_count,
            num_partitions,
        )

    if num_partitions is None:
        num_partitions = 1

    column_list = ", ".join(columns)
    source_query = f"(SELECT {column_list} FROM {source_table}) src"

    reader = (
        spark.read
        .format("jdbc")
        .option("url", oracle_jdbc_url)
        .option("user", oracle_user)
        .option("password", oracle_password)
        .option("driver", "oracle.jdbc.OracleDriver")
        .option("dbtable", source_query)
        .option("fetchsize", "10000")
    )

    if partition_column and lower_bound is not None and upper_bound is not None:
        logging.info("Reading %s with JDBC partitioning", source_table)

        reader = (
            reader
            .option("partitionColumn", partition_column)
            .option("lowerBound", str(to_int(lower_bound)))
            .option("upperBound", str(to_int(upper_bound)))
            .option("numPartitions", str(num_partitions))
        )
    else:
        logging.info("Reading %s without JDBC partitioning", source_table)

    df = reader.load()

    logging.info("Writing to CockroachDB table: %s", target_table)

    writer = (
        df.write
        .format("jdbc")
        .option("url", cockroach_jdbc_url)
        .option("user", cockroach_user)
        .option("driver", "org.postgresql.Driver")
        .option("dbtable", target_table)
        .option("batchsize", "5000")
        .option("isolationLevel", "NONE")
        .mode("append")
    )

    if cockroach_password:
        writer = writer.option("password", cockroach_password)

    writer.save()

    logging.info("Finished syncing %s -> %s", source_table, target_table)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--configs", required=True)

    args = parser.parse_args()
    table_configs = json.loads(args.configs)

    oracle_jdbc_url = required_env("ORACLE_JDBC_URL")
    oracle_user = required_env("ORACLE_USER")
    oracle_password = required_env("ORACLE_PASSWORD")

    cockroach_jdbc_url = required_env("COCKROACH_JDBC_URL")
    cockroach_user = required_env("COCKROACH_USER")
    cockroach_password = os.environ.get("COCKROACH_PASSWORD", "")

    spark = (
        SparkSession.builder
        .appName("sync_all_tables_one_spark_session")
        .config("spark.sql.shuffle.partitions", "8")
        .getOrCreate()
    )

    try:
        for table_config in table_configs:
            sync_one_table(
                spark=spark,
                table_config=table_config,
                oracle_jdbc_url=oracle_jdbc_url,
                oracle_user=oracle_user,
                oracle_password=oracle_password,
                cockroach_jdbc_url=cockroach_jdbc_url,
                cockroach_user=cockroach_user,
                cockroach_password=cockroach_password,
            )

    finally:
        logging.info("Stopping SparkSession")
        spark.stop()


if __name__ == "__main__":
    main()