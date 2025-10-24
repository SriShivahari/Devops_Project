#!/usr/bin/env python3
"""
Test script for the Language Detection API
"""

import requests
import json

# API base URL
BASE_URL = "http://localhost:5000"

def test_health():
    """Test health endpoint"""
    print("🔍 Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print("✅ Health check passed")
            print(f"Response: {response.json()}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Health check error: {e}")

def test_languages():
    """Test languages endpoint"""
    print("\n🔍 Testing languages endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/languages")
        if response.status_code == 200:
            print("✅ Languages endpoint working")
            languages = response.json()['supported_languages']
            print(f"Supported languages: {len(languages)}")
            print(f"Sample languages: {languages[:5]}...")
        else:
            print(f"❌ Languages endpoint failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Languages endpoint error: {e}")

def test_prediction():
    """Test prediction endpoint"""
    print("\n🔍 Testing prediction endpoint...")
    
    test_texts = [
        "Hello, how are you today?",
        "Bonjour, comment allez-vous?",
        "Hola, ¿cómo estás?",
        "Guten Tag, wie geht es Ihnen?",
        "Привет, как дела?",
        "你好，你好吗？",
        "مرحبا، كيف حالك؟"
    ]
    
    for text in test_texts:
        try:
            response = requests.post(
                f"{BASE_URL}/predict",
                json={"text": text},
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Text: '{text[:30]}...'")
                print(f"   Predicted: {result['predicted_language']} (Confidence: {result['confidence']}%)")
            else:
                print(f"❌ Prediction failed for '{text[:30]}...': {response.status_code}")
                
        except Exception as e:
            print(f"❌ Prediction error for '{text[:30]}...': {e}")

def main():
    """Run all tests"""
    print("🚀 Starting API Tests...")
    print("=" * 50)
    
    test_health()
    test_languages()
    test_prediction()
    
    print("\n" + "=" * 50)
    print("🏁 Tests completed!")

if __name__ == "__main__":
    main()

