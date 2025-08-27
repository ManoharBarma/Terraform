#!/bin/bash
# This script generates a dependency graph for the Terraform configuration in this directory.

terraform graph > graph.dot
dot -Tpng graph.dot -o graph.png
echo "Dependency graph generated: graph.png"
