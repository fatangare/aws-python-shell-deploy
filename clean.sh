#!/usr/bin/env bash
find . | grep -E "(\.pytest_cache|spark_warehouse|metastore_db|\.log|\__pycache__|\.pyc|\.pyo$|spark-warehouse)" | xargs rm -rf

rm -rf dist
