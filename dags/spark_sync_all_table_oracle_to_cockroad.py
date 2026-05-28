from datetime import datetime
import json

from airflow import DAG
from airflow.hooks.base import BaseHook
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator


ORACLE_CONN_ID = "oracle_connection"
COCKROACH_CONN_ID = "cockroach_connection"

SPARK_ONE_APP = "/opt/airflow/dags/spark/spark_sync_table.py"
SPARK_MANY_APP = "/opt/airflow/dags/spark/spark_sync_many_tables.py"

ORACLE_JAR = "/opt/airflow/jars/ojdbc17.jar"
POSTGRES_PACKAGE = "org.postgresql:postgresql:42.7.3"


def get_oracle_env(conn_id: str):
    conn = BaseHook.get_connection(conn_id)

    host = conn.host
    port = conn.port or 1521
    user = conn.login
    password = conn.password

    extra = conn.extra_dejson or {}
    service_name = extra.get("service_name")
    sid = extra.get("sid")

    if service_name:
        jdbc_url = f"jdbc:oracle:thin:@//{host}:{port}/{service_name}"
    elif sid:
        jdbc_url = f"jdbc:oracle:thin:@{host}:{port}:{sid}"
    else:
        raise ValueError(
            "Oracle connection cần Extra có service_name hoặc sid. "
            'Ví dụ: {"service_name":"XEPDB1"}'
        )

    return {
        "ORACLE_JDBC_URL": jdbc_url,
        "ORACLE_USER": user,
        "ORACLE_PASSWORD": password,
    }


def get_cockroach_env(conn_id: str):
    conn = BaseHook.get_connection(conn_id)

    host = conn.host
    port = conn.port or 26257
    database = conn.schema or "defaultdb"
    user = conn.login or "root"
    password = conn.password or ""

    extra = conn.extra_dejson or {}
    sslmode = extra.get("sslmode", "disable")

    jdbc_url = f"jdbc:postgresql://{host}:{port}/{database}?sslmode={sslmode}"

    return {
        "COCKROACH_JDBC_URL": jdbc_url,
        "COCKROACH_USER": user,
        "COCKROACH_PASSWORD": password,
    }


TABLE_CONFIGS = {
    "branches": {
        "source_table": "BRANCHES",
        "target_table": "branches",
        "columns": [
            "branch_id",
            "branch_name",
            "address",
            "city",
            "country",
            "phone_number",
        ],
    },
    "employees": {
        "source_table": "EMPLOYEES",
        "target_table": "employees",
        "columns": [
            "employee_id",
            "first_name",
            "last_name",
            "email",
            "phone_number",
            "hire_date",
            "salary",
            "branch_id",
        ],
    },
    "products_info": {
        "source_table": "PRODUCTS_INFO",
        "target_table": "products_info",
        "columns": [
            "product_id",
            "product_name",
            "category",
            "brand",
        ],
    },
    "products_stock": {
        "source_table": "PRODUCTS_STOCK",
        "target_table": "products_stock",
        "columns": [
            "product_id",
            "branch_id",
            "stock_quantity",
            "unit_price_usd",
        ],
    },
    "customers": {
        "source_table": "CUSTOMERS",
        "target_table": "customers",
        "columns": [
            "customer_id",
            "customer_name",
            "gender",
            "age",
            "country",
            "city",
        ],
        "partition_column": "customer_id",
    },
    "orders": {
        "source_table": "ORDERS",
        "target_table": "orders",
        "columns": [
            "order_id",
            "order_date",
            "customer_id",
            "employee_id",
            "branch_id",
            "payment_method",
            "tax_usd",
            "total_price_usd",
        ],
        "partition_column": "order_id",
    },
    "order_items": {
        "source_table": "ORDER_ITEMS",
        "target_table": "order_items",
        "columns": [
            "order_id",
            "product_id",
            "quantity",
            "discount_percent",
            "discount_amount_usd",
            "unit_price_usd",
            "total_price_usd",
        ],
        "partition_column": "order_id",
    },
}


def create_spark_sync_one_task(
    table_name: str,
    config: dict,
    spark_env: dict,
    driver_memory: str,
    shuffle_partitions: str,
):
    return SparkSubmitOperator(
        task_id=f"sync_{table_name}",
        application=SPARK_ONE_APP,
        conn_id="spark_default",
        application_args=[
            "--config",
            json.dumps(config),
        ],
        jars=ORACLE_JAR,
        packages=POSTGRES_PACKAGE,
        name=f"spark_sync_{table_name}",
        conf={
            "spark.driver.memory": driver_memory,
            "spark.sql.shuffle.partitions": shuffle_partitions,
        },
        env_vars=spark_env,
        verbose=True,
    )


def create_spark_sync_many_task(
    task_id: str,
    configs: list[dict],
    spark_env: dict,
):
    return SparkSubmitOperator(
        task_id=task_id,
        application=SPARK_MANY_APP,
        conn_id="spark_default",
        application_args=[
            "--configs",
            json.dumps(configs),
        ],
        jars=ORACLE_JAR,
        packages=POSTGRES_PACKAGE,
        name=task_id,
        conf={
            "spark.driver.memory": "1g",
            "spark.sql.shuffle.partitions": "2",
        },
        env_vars=spark_env,
        verbose=True,
    )


with DAG(
    dag_id="spark_sync_all_tables",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    max_active_tasks=1,
    tags=["spark", "oracle", "cockroach", "sync"],
):
    spark_env = {}
    spark_env.update(get_oracle_env(ORACLE_CONN_ID))
    spark_env.update(get_cockroach_env(COCKROACH_CONN_ID))

    sync_small_tables = create_spark_sync_many_task(
        task_id="sync_small_tables",
        configs=[
            TABLE_CONFIGS["branches"],
            TABLE_CONFIGS["employees"],
            TABLE_CONFIGS["products_info"],
            TABLE_CONFIGS["products_stock"],
        ],
        spark_env=spark_env,
    )

    sync_customers = create_spark_sync_one_task(
        table_name="customers",
        config=TABLE_CONFIGS["customers"],
        spark_env=spark_env,
        driver_memory="2g",
        shuffle_partitions="8",
    )

    sync_orders = create_spark_sync_one_task(
        table_name="orders",
        config=TABLE_CONFIGS["orders"],
        spark_env=spark_env,
        driver_memory="1g",
        shuffle_partitions="4",
    )

    sync_order_items = create_spark_sync_one_task(
        table_name="order_items",
        config=TABLE_CONFIGS["order_items"],
        spark_env=spark_env,
        driver_memory="1g",
        shuffle_partitions="4",
    )

    sync_small_tables >> sync_customers >> sync_orders >> sync_order_items