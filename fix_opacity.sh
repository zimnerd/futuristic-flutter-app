#!/bin/bash

# Script to replace withOpacity with withValues(alpha:) in Dart files

FILES=$(rg -l "withOpacity" lib/presentation)

for file in $FILES; do
    echo "Processing $file..."
    sed -i '' 's/\.withOpacity(\([^)]*\))/.withValues(alpha: \1)/g' "$file"
done

echo "Replacement complete!"
