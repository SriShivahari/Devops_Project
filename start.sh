#!/bin/bash

echo "🚀 Starting Language Detection Model Container..."

# Check if dataset exists
if [ ! -f "dataset.csv" ]; then
    echo "❌ Error: dataset.csv not found!"
    echo "Please make sure dataset.csv is in the container"
    exit 1
fi

echo "✅ Dataset found: dataset.csv"

# Check if model file exists, if not train the model
if [ ! -f "models/modelname.pth" ]; then
    echo "🤖 Model not found. Starting training..."
    echo "This may take 20-30 minutes..."
    
    # Run the training notebook
    jupyter nbconvert --to python --execute VML\(2\).ipynb --stdout > training_output.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Model training completed successfully!"
    else
        echo "❌ Model training failed. Check training_output.log for details"
        exit 1
    fi
else
    echo "✅ Pre-trained model found: models/modelname.pth"
fi

# Start the Flask API
echo "🌐 Starting Flask API server..."
python app.py

