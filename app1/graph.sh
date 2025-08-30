#!/bin/bash

terraform graph > graph.dot
dot -Tpng graph.dot -o graph.png
echo "Dependency graph generated: graph.png"
