# GideonBoxingAI

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.9%2B-blue.svg)](https://python.org)
[![React Native](https://img.shields.io/badge/React%20Native-0.79.5-blue.svg)](https://reactnative.dev)
[![Build Status](https://img.shields.io/badge/Build-MVP%20Stage-yellow.svg)]()
[![PyTorch](https://img.shields.io/badge/PyTorch-Latest-red.svg)](https://pytorch.org)

> **⚠️ MVP STAGE WARNING**: This project is currently in MVP stage with known critical pipeline issues. See [Known Issues](#known-issues) for details.

An AI-powered boxing technique analysis system that provides real-time feedback on form, stance, and defensive positioning using computer vision and machine learning.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Current Status](#current-status)
- [Architecture Overview](#architecture-overview)
- [Components](#components)
- [Setup Instructions](#setup-instructions)
- [Development Roadmap](#development-roadmap)
- [Known Issues](#known-issues)
- [Contributing Guidelines](#contributing-guidelines)
- [License](#license)

## 🎯 Project Overview

GideonBoxingAI is a comprehensive boxing analysis platform that combines computer vision, machine learning, and mobile technology to provide real-time feedback on boxing technique. The system analyzes video footage to detect biomechanical patterns, stance quality, and defensive vulnerabilities.

### Key Features

- **Real-time Pose Analysis**: MediaPipe-based pose estimation for boxing movements
- **Mobile Integration**: React Native app for iOS with real-time video analysis
- **Web-based Labeling Interface**: NextJS application for data annotation and model training
- **ML Pipeline**: PyTorch-based training pipeline for technique classification
- **Cloud Integration**: Supabase backend for data storage and user management

### Target Use Cases

- **Training Enhancement**: Real-time feedback for amateur boxers
- **Performance Analysis**: Detailed breakdown of technique for coaches
- **Skill Assessment**: Objective scoring of boxing fundamentals
- **Remote Coaching**: Cloud-based analysis for remote training scenarios

## 🚦 Current Status

**Stage**: MVP (Minimum Viable Product)
**Version**: 1.0.0
**Last Updated**: September 2024

### MVP Capabilities

✅ **Basic Pose Extraction**: MediaPipe integration for keypoint detection
✅ **Mobile App**: React Native iOS application with video recording
✅ **Web Labeling Tool**: NextJS interface for manual data annotation
✅ **Training Scripts**: Basic PyTorch model training pipeline
✅ **Database Integration**: Supabase for data storage and management

### In Development

🔄 **Enhanced Feature Engineering**: Biomechanical feature extraction
🔄 **Multi-annotator System**: Quality assurance for training data
🔄 **Pipeline Automation**: Automated data processing workflows
🔄 **CoreML Integration**: On-device inference for iOS

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   iOS Mobile    │    │   Web Labeling   │    │  Training       │
│   (React Native)│    │   (NextJS)       │    │  Pipeline       │
│                 │    │                  │    │  (Python)       │
└─────────┬───────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
          │              ┌───────▼────────┐             │
          │              │   Supabase     │             │
          └──────────────►   Database     ◄─────────────┘
                         │   (PostgreSQL) │
                         └────────────────┘
                                 │
                         ┌───────▼────────┐
                         │  Google Drive  │
                         │  Video Storage │
                         └────────────────┘
```

### Technology Stack

- **Frontend**: React Native (iOS), NextJS (Web)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **ML Framework**: PyTorch, MediaPipe, CoreML
- **Video Processing**: OpenCV, FFmpeg
- **Cloud Storage**: Google Drive API
- **Deployment**: Vercel (Web), Expo (Mobile)

## 🔧 Components

### iOS Integration (Swift/React Native)

**Location**: `/gideon-mobile/`

**Key Files**:
- `/gideon-mobile/App.tsx` - Main application component
- `/gideon-mobile/VideoPlayer.tsx` - Video recording and playback
- `/gideon-mobile/analyze_video.py` - Python analysis backend
- `/gideon-mobile/model_server.py` - Model inference server

**Features**:
- Real-time video recording and analysis
- MediaPipe pose estimation integration
- Supabase authentication and data sync
- CoreML model integration (planned)

**Dependencies**:
```json
{
  "expo": "~53.0.20",
  "react-native": "0.79.5",
  "@supabase/supabase-js": "^2.55.0",
  "expo-av": "^15.1.7"
}
```

### ML Model (PyTorch/CoreML)

**Location**: `/train_model.py`, `/extract_poses.py`

**Key Files**:
- `/train_model.py` - Main training script
- `/extract_poses.py` - Pose extraction pipeline
- `/gideon_training_colab.ipynb` - Jupyter training notebook
- `/PRODUCTION_PIPELINE_ARCHITECTURE.py` - Production pipeline design

**Features**:
- MediaPipe pose estimation
- PyTorch neural network training
- Feature engineering pipeline
- CoreML conversion utilities

**Model Architecture**:
- Input: 33 MediaPipe keypoints (x, y, z, visibility)
- Hidden Layers: Configurable dense layers with dropout
- Output: Multi-class boxing technique classification
- Loss Function: CrossEntropyLoss with class weighting

### Training Pipeline

**Location**: Root directory and `/gideon-labeling/scripts/`

**Key Files**:
- `/requirements.txt` - Python dependencies
- `/setup.sh` - Environment setup script
- `/gideon-labeling/scripts/train_gideon_from_labels.py` - Label-based training
- `/gideon-labeling/scripts/gideon_training_monitor.py` - Training monitoring

**Pipeline Stages**:
1. **Data Ingestion**: Google Drive video download
2. **Pose Extraction**: MediaPipe keypoint detection
3. **Feature Engineering**: Biomechanical feature calculation
4. **Data Labeling**: Web interface for annotation
5. **Model Training**: PyTorch training with validation
6. **Model Export**: CoreML conversion for mobile deployment

### Labeling Interface

**Location**: `/gideon-labeling/`

**Key Files**:
- `/gideon-labeling/src/` - NextJS application source
- `/gideon-labeling/package.json` - Dependencies and scripts
- `/gideon-labeling/scripts/` - Training and utility scripts

**Features**:
- Video timeline annotation interface
- Multi-class labeling system
- Google Drive integration
- Supabase data persistence
- Export capabilities for training

**Dependencies**:
```json
{
  "next": "14.2.5",
  "react": "18.3.1",
  "@supabase/supabase-js": "2.45.0",
  "googleapis": "^156.0.0",
  "video.js": "8.10.0"
}
```

## 🚀 Setup Instructions

### Prerequisites

- **Python**: 3.9 or higher
- **Node.js**: 18.0 or higher
- **iOS Development**: Xcode 14+ (for mobile development)
- **Database**: Supabase account and project
- **Storage**: Google Drive API credentials

### 1. Environment Setup

```bash
# Clone the repository
git clone <repository-url>
cd Gideon_v1

# Create Python virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Run setup script
chmod +x setup.sh
./setup.sh
```

### 2. Database Configuration

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Set up the database schema (see `/gideon-labeling/setup-database.md`)
3. Configure environment variables:

```bash
# .env.local
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_DRIVE_CREDENTIALS=path_to_credentials.json
```

### 3. Web Labeling Interface

```bash
cd gideon-labeling

# Install dependencies
npm install

# Start development server
npm run dev

# Open http://localhost:3000
```

### 4. Mobile Application

```bash
cd gideon-mobile

# Install dependencies
npm install

# Start Expo development server
npm start

# Follow Expo CLI instructions for iOS/Android deployment
```

### 5. Model Training

```bash
# Extract poses from videos
python extract_poses.py --input data/videos --output data/poses

# Train the model
python train_model.py --data data/poses --output models/gideon_v1

# Monitor training progress
python gideon-labeling/scripts/gideon_training_monitor.py
```

## 📅 Development Roadmap

### 6-Week Production Pipeline Plan

Based on the `REMEDIATION_ROADMAP.md`, here's the development timeline:

#### **Week 1: Critical Fixes**
- 🔒 **Security**: Remove hardcoded credentials, implement secrets management
- 📊 **Data Versioning**: Implement DVC for data tracking and versioning
- ✅ **Data Validation**: Add data integrity checks and validation pipeline
- 🔄 **Pipeline Fixes**: Replace blocking I/O with async processing

#### **Week 2: Feature Engineering**
- 🦴 **Biomechanical Features**: Joint angles, velocities, accelerations
- 📐 **Spatial Features**: Fighter positioning, distance calculations
- ⏱️ **Temporal Features**: Motion trajectories, frequency analysis
- 🎯 **Derived Metrics**: Guard position quality, balance indicators

#### **Week 3: Quality Assurance**
- 👥 **Multi-Annotator System**: Implement consensus-based labeling
- 📈 **Quality Metrics**: Inter-annotator agreement, confidence scoring
- 🔍 **Data Validation**: Automated quality checks and outlier detection
- 📊 **Analytics Dashboard**: Training data quality monitoring

#### **Week 4: Automation Infrastructure**
- 🐳 **Containerization**: Docker containers for all components
- 🔄 **Orchestration**: Airflow DAGs for automated pipeline execution
- 📊 **Monitoring**: Prometheus metrics and alerting system
- 🚀 **CI/CD**: Automated testing and deployment pipelines

#### **Weeks 5-6: Production Deployment**
- 🧪 **Comprehensive Testing**: End-to-end integration tests
- 📊 **Performance Benchmarking**: Latency and throughput optimization
- 🔐 **Security Audit**: Penetration testing and vulnerability assessment
- 🌐 **Production Deployment**: Cloud infrastructure and scaling

### **Success Metrics**

| Metric | Current | Target |
|--------|---------|--------|
| Pipeline Reliability | 15% | 95% |
| Automation Coverage | 5% | 90% |
| Data Quality Score | 20% | 85% |
| Reproducibility | 0% | 100% |
| Security Score | 10% | 90% |

## ⚠️ Known Issues

### Critical Pipeline Issues

Based on the `PIPELINE_CRITICAL_ANALYSIS.md`, the following critical issues exist:

#### **Data Pipeline Failures (CRITICAL)**
- ❌ **Manual Processing**: No automated ingestion from Google Drive
- ❌ **Blocking I/O**: Sequential video processing causes timeouts
- ❌ **No Data Versioning**: Cannot reproduce training runs
- ❌ **Single Annotator**: No quality control or inter-annotator agreement

#### **Security Vulnerabilities (CRITICAL)**
- 🔓 **Hardcoded Credentials**: Supabase keys exposed in source code
- 🔓 **No Encryption**: Data stored without encryption at rest
- 🔓 **No Access Control**: No authentication for pipeline components

#### **Feature Engineering Gaps (HIGH)**
- 📉 **Raw Features Only**: Only using basic x,y,z keypoints
- ⏰ **No Temporal Analysis**: Missing velocity and acceleration features
- 🦴 **No Biomechanics**: Missing joint angles and kinematic analysis
- 📐 **No Spatial Relations**: Missing fighter-to-fighter positioning

#### **Infrastructure Issues (HIGH)**
- 🚫 **No Orchestration**: Manual script execution only
- 📊 **No Monitoring**: No pipeline health or performance metrics
- 🐳 **No Containerization**: Environment not reproducible
- 🔄 **No CI/CD**: No automated testing or deployment

### Immediate Actions Required

1. **STOP** using current pipeline for production data
2. **IMPLEMENT** data versioning with DVC immediately
3. **REMOVE** hardcoded credentials and implement secrets management
4. **ADD** data validation and quality checks
5. **PLAN** complete pipeline rebuild (estimated 4-6 weeks)

## 🤝 Contributing Guidelines

### Development Process

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/your-feature-name`
3. **Follow** coding standards and add tests
4. **Submit** a pull request with detailed description

### Code Standards

- **Python**: Follow PEP 8, use type hints, add docstrings
- **TypeScript**: Use strict mode, follow ESLint configuration
- **Testing**: Minimum 80% code coverage for new features
- **Documentation**: Update README and inline documentation

### Testing Requirements

```bash
# Python tests
pytest tests/ --cov=src --cov-report=html

# TypeScript tests
npm test -- --coverage

# Integration tests
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

### Pull Request Process

1. Update documentation for any new features
2. Add tests with appropriate coverage
3. Ensure all CI checks pass
4. Request review from maintainers
5. Address feedback and rebase as needed

### Issue Reporting

When reporting issues, please include:
- **Environment**: OS, Python/Node version, dependencies
- **Steps to Reproduce**: Detailed reproduction steps
- **Expected vs Actual**: Clear description of the problem
- **Logs**: Relevant error messages and stack traces

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 GideonBoxingAI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)
- **Email**: support@gideonboxingai.com

---

**⚠️ Production Warning**: This system is currently in MVP stage with known critical issues. Do not use for production boxing analysis without implementing the remediation roadmap. See [REMEDIATION_ROADMAP.md](REMEDIATION_ROADMAP.md) for required fixes.