# Language Detection Model - Docker Deployment

This project containerizes a BERT-based language detection model using Docker and provides a REST API for predictions.

## 🚀 Quick Start

### Prerequisites
- Docker Desktop installed and running
- `dataset.csv` file in the project directory

### 1. Build and Run with Docker Compose (Recommended)

```bash
# Build and start all services
docker-compose up --build

# Run in background
docker-compose up -d --build
```

### 2. Build and Run with Docker

```bash
# Build the image
docker build -t language-detection .

# Run the container
docker run -p 5000:5000 -v $(pwd)/models:/app/models -v $(pwd)/dataset.csv:/app/dataset.csv language-detection
```

## 📊 API Endpoints

### Health Check
```bash
GET http://localhost:5000/health
```

### Get Supported Languages
```bash
GET http://localhost:5000/languages
```

### Predict Language
```bash
POST http://localhost:5000/predict
Content-Type: application/json

{
    "text": "Hello, how are you?"
}
```

### Response Example
```json
{
    "text": "Hello, how are you?",
    "predicted_language": "English",
    "confidence": 95.67,
    "all_predictions": {
        "Arabic": 0.1,
        "Chinese": 0.2,
        "English": 95.67,
        ...
    }
}
```

## 🧪 Testing

Run the test script to verify the API:

```bash
python test_api.py
```

## 📁 Project Structure

```
├── VML(2).ipynb          # Jupyter notebook with model training
├── dataset.csv           # Training dataset
├── app.py               # Flask API application
├── Dockerfile           # Docker configuration
├── docker-compose.yml   # Docker Compose configuration
├── requirements.txt     # Python dependencies
├── start.sh            # Container startup script
├── nginx.conf          # Nginx reverse proxy config
├── test_api.py         # API testing script
└── README.md           # This file
```

## 🔧 Configuration

### Environment Variables
- `FLASK_ENV`: Set to `production` for production deployment
- `PYTHONPATH`: Set to `/app` for proper module imports

### Ports
- **5000**: Flask API (direct access)
- **80**: Nginx reverse proxy (recommended for production)

## 🏗️ Development

### Local Development
1. Install dependencies: `pip install -r requirements.txt`
2. Run the notebook: `jupyter notebook VML(2).ipynb`
3. Start the API: `python app.py`

### Container Development
1. Make changes to your code
2. Rebuild: `docker-compose up --build`
3. Test: `python test_api.py`

## 📈 Monitoring

### Health Checks
The container includes health checks that monitor:
- API availability
- Model loading status
- Container health

### Logs
View container logs:
```bash
docker-compose logs -f language-detection
```

## 🚀 Production Deployment

### Using Docker Compose (Recommended)
```bash
# Production deployment
docker-compose -f docker-compose.yml up -d
```

### Using Docker Swarm
```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml language-detection
```

### Using Kubernetes
Convert docker-compose to Kubernetes manifests:
```bash
# Install kompose
pip install kompose

# Convert
kompose convert
```

## 🔍 Troubleshooting

### Common Issues

1. **Model not found**: Ensure `dataset.csv` is in the project directory
2. **Port conflicts**: Change ports in `docker-compose.yml`
3. **Memory issues**: Increase Docker memory allocation
4. **Training fails**: Check logs with `docker-compose logs language-detection`

### Debug Mode
Run container in debug mode:
```bash
docker run -it --entrypoint /bin/bash language-detection
```

## 📝 Notes

- First run will train the model (takes 20-30 minutes)
- Model weights are saved to `./models/` directory
- API supports 22 languages
- Confidence scores are returned as percentages

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `python test_api.py`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## CI/CD Pipeline Active!
