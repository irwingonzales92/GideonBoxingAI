# GideonBoxingAI MVP - Technical Architecture Document

**Version:** 1.0
**Last Updated:** October 21, 2025
**Status:** MVP Architecture Specification
**Target:** B2B Gym Installation System

---

## Executive Summary

GideonBoxingAI is an AI-powered gym system that uses fixed camera stations to assess boxing technique and generate personalized workouts. This document outlines the complete technical architecture for a 6-month MVP deployment targeting gym owners (B2B model).

**Key Differentiators:**
- Fixed installation in gyms (not a mobile app)
- Real-time shadowboxing analysis at assessment stations
- AI-generated personalized workouts using gym equipment
- B2B sales model with recurring revenue per gym

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [System Components](#2-system-components)
3. [Technology Stack](#3-technology-stack)
4. [Data Flow Architecture](#4-data-flow-architecture)
5. [MVP Development Roadmap](#5-mvp-development-roadmap)
6. [Hardware Requirements](#6-hardware-requirements)
7. [Performance Requirements](#7-performance-requirements)
8. [Project Structure](#8-project-structure)
9. [API Specifications](#9-api-specifications)
10. [Deployment Architecture](#10-deployment-architecture)
11. [Security & Compliance](#11-security--compliance)
12. [Cost Analysis](#12-cost-analysis)
13. [Risk Mitigation](#13-risk-mitigation)

---

## 1. System Overview

### 1.1 Product Vision

GideonBoxingAI transforms boxing gyms by providing AI-powered technique assessment and personalized workout generation. Members use fixed camera stations to perform shadowboxing routines, receive instant AI analysis, and get customized workouts displayed on gym tablets.

### 1.2 Architecture Principles

- **Edge Computing First**: Process video locally to reduce latency and bandwidth
- **Cloud Brain**: Complex AI analysis and workout generation in cloud
- **Offline Capable**: Core assessment works without internet
- **Scalable**: Single gym to 1000+ gyms with same architecture
- **B2B Focused**: Multi-tenant, gym-branded, owner dashboards

### 1.3 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        ASSESSMENT STATION                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  Cameras     │  │  Edge Device │  │  Member Tablet       │  │
│  │  (2x RGB)    │──▶│  (Nvidia     │──▶│  (iPad/Android)      │  │
│  │              │  │  Jetson)     │  │                      │  │
│  └──────────────┘  └──────┬───────┘  └──────────────────────┘  │
└────────────────────────────┼─────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   INTERNET      │
                    └────────┬────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                     CLOUD INFRASTRUCTURE                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Backend API (FastAPI/Python)                │   │
│  │  - Workout Generation AI                                 │   │
│  │  - Member Management                                     │   │
│  │  - Analytics & Reporting                                 │   │
│  └───────┬──────────────────────────────────────────┬───────┘   │
│          │                                           │           │
│  ┌───────▼──────────┐                    ┌──────────▼────────┐  │
│  │   PostgreSQL     │                    │   Object Storage  │  │
│  │   Database       │                    │   (S3/GCS)        │  │
│  └──────────────────┘                    └───────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           Gym Owner Dashboard (React/Next.js)            │   │
│  │  - Member Analytics                                      │   │
│  │  - Equipment Management                                  │   │
│  │  - Revenue Reporting                                     │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. System Components

### 2.1 Assessment Station (Edge)

**Purpose**: Capture and analyze shadowboxing technique in real-time

**Components**:

#### 2.1.1 Camera System
- **Hardware**: 2x RGB cameras (e.g., Logitech Brio 4K)
- **Positioning**:
  - Camera 1: Front-facing (0°), 8ft from member, 5ft height
  - Camera 2: Side-facing (90°), 8ft from member, 5ft height
- **Specs**: 1080p @ 30fps minimum, synchronized capture
- **Mount**: Adjustable tripod or wall mount with cable management

#### 2.1.2 Edge Compute Device
- **Hardware**: Nvidia Jetson Orin Nano (8GB) or Jetson AGX Orin
- **Purpose**: Real-time pose estimation and video preprocessing
- **Software Stack**:
  - Ubuntu 20.04 LTS
  - Python 3.9+
  - MediaPipe 0.10+ (pose estimation)
  - OpenCV 4.8+ (video processing)
  - TensorRT (model acceleration)
  - Docker (containerization)

#### 2.1.3 Local Processing Pipeline
```python
# Pseudo-code for edge processing
class EdgeProcessor:
    def __init__(self):
        self.pose_estimator = MediaPipe(model='blazepose')
        self.camera_sync = CameraSynchronizer()

    def process_assessment(self, duration_seconds=60):
        """
        Real-time assessment processing
        """
        # 1. Capture synchronized video from both cameras
        video_streams = self.camera_sync.capture_dual(duration_seconds)

        # 2. Extract poses frame-by-frame
        poses_front = self.pose_estimator.extract(video_streams['front'])
        poses_side = self.pose_estimator.extract(video_streams['side'])

        # 3. Calculate basic metrics (edge)
        metrics = {
            'stance_quality': calculate_stance(poses_front, poses_side),
            'guard_position': calculate_guard(poses_front),
            'movement_speed': calculate_speed(poses_front),
            'balance_score': calculate_balance(poses_side),
        }

        # 4. Compress and send to cloud for deep analysis
        compressed_data = {
            'poses': compress_poses([poses_front, poses_side]),
            'basic_metrics': metrics,
            'video_thumbnail': extract_thumbnail(video_streams['front']),
            'timestamp': datetime.utcnow(),
        }

        # 5. Send to cloud API
        response = self.cloud_api.analyze_and_generate_workout(
            member_id=current_member_id,
            assessment_data=compressed_data
        )

        return response
```

#### 2.1.4 Edge Server (Flask/FastAPI)
```python
# edge_server.py
from fastapi import FastAPI, WebSocket
from edge_processor import EdgeProcessor

app = FastAPI()
processor = EdgeProcessor()

@app.websocket("/ws/assessment")
async def assessment_stream(websocket: WebSocket):
    """Stream real-time assessment to tablet"""
    await websocket.accept()

    async for frame_data in processor.stream_assessment():
        await websocket.send_json({
            'pose_overlay': frame_data.pose_keypoints,
            'live_metrics': frame_data.metrics,
            'feedback': frame_data.instant_feedback
        })

@app.post("/api/start-assessment")
async def start_assessment(member_id: str):
    """Initiate assessment session"""
    result = await processor.process_assessment(member_id)
    return result
```

### 2.2 Member Tablet Interface

**Purpose**: Member interaction, assessment display, workout viewing

**Hardware**:
- iPad (10.2" or larger) OR Android tablet (Samsung Galaxy Tab A8)
- Wall-mounted with charging dock
- Optional: Bluetooth heart rate monitor integration

**Software Stack**:
- **Framework**: React Native (cross-platform iOS/Android)
- **State Management**: Redux Toolkit
- **API Client**: Axios with retry logic
- **Offline Storage**: AsyncStorage / SQLite
- **UI Library**: React Native Paper (Material Design)

**Key Screens**:

1. **Member Check-In**
   - QR code scan or PIN entry
   - Face recognition (Phase 2)

2. **Assessment Instructions**
   - 60-second shadowboxing routine guide
   - Camera positioning feedback
   - Countdown timer

3. **Live Assessment View**
   - Real-time pose overlay
   - Instant feedback messages
   - Progress indicator

4. **Results & Workout Display**
   - Assessment scores visualization
   - Personalized workout routine
   - Equipment map (location in gym)
   - Video demonstrations

**Code Structure**:
```typescript
// src/screens/AssessmentScreen.tsx
import React, { useEffect, useState } from 'react';
import { View, Text } from 'react-native';
import { useWebSocket } from '@/hooks/useWebSocket';

export const AssessmentScreen: React.FC<Props> = ({ memberId }) => {
  const { connect, sendMessage, messages } = useWebSocket(
    `ws://${EDGE_DEVICE_IP}/ws/assessment`
  );

  const [assessmentData, setAssessmentData] = useState({
    poseOverlay: null,
    liveMetrics: {},
    feedback: []
  });

  useEffect(() => {
    connect();
    sendMessage({ action: 'start', memberId });
  }, []);

  useEffect(() => {
    if (messages.length > 0) {
      const latest = messages[messages.length - 1];
      setAssessmentData(latest);
    }
  }, [messages]);

  return (
    <View style={styles.container}>
      <PoseOverlay data={assessmentData.poseOverlay} />
      <MetricsPanel metrics={assessmentData.liveMetrics} />
      <FeedbackDisplay items={assessmentData.feedback} />
    </View>
  );
};
```

### 2.3 Cloud Backend (AI Brain)

**Purpose**: Deep analysis, workout generation, data management, gym dashboards

**Infrastructure**: AWS (recommended for MVP)

#### 2.3.1 Backend API

**Framework**: FastAPI (Python 3.11+)

**Key Services**:

```python
# app/services/workout_generator.py
from typing import List, Dict
import openai
from app.models import AssessmentData, Workout, Member

class WorkoutGeneratorService:
    def __init__(self):
        self.gpt_client = openai.OpenAI()

    async def generate_personalized_workout(
        self,
        member: Member,
        assessment: AssessmentData,
        gym_equipment: List[str]
    ) -> Workout:
        """
        Generate AI-powered personalized workout
        """
        # 1. Analyze biomechanical data
        biomech_analysis = self._analyze_biomechanics(assessment)

        # 2. Identify weaknesses and strengths
        insights = {
            'weaknesses': self._identify_weaknesses(biomech_analysis),
            'strengths': self._identify_strengths(biomech_analysis),
            'injury_risk': self._assess_injury_risk(biomech_analysis),
        }

        # 3. Generate workout with GPT-4
        prompt = self._build_workout_prompt(
            member_profile=member.to_dict(),
            assessment_insights=insights,
            available_equipment=gym_equipment,
            previous_workouts=member.workout_history[-5:]
        )

        gpt_response = await self.gpt_client.chat.completions.create(
            model="gpt-4-turbo",
            messages=[
                {"role": "system", "content": WORKOUT_SYSTEM_PROMPT},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"}
        )

        workout_json = json.loads(gpt_response.choices[0].message.content)

        # 4. Validate and save workout
        workout = Workout.from_json(workout_json)
        workout.member_id = member.id
        workout.assessment_id = assessment.id

        await workout.save()

        return workout

    def _build_workout_prompt(self, **kwargs) -> str:
        """Build GPT-4 prompt for workout generation"""
        return f"""
        Generate a personalized boxing workout for:

        MEMBER PROFILE:
        - Experience: {kwargs['member_profile']['experience_level']}
        - Goals: {kwargs['member_profile']['goals']}
        - Limitations: {kwargs['member_profile']['injuries_or_limitations']}

        ASSESSMENT INSIGHTS:
        - Weaknesses: {kwargs['assessment_insights']['weaknesses']}
        - Strengths: {kwargs['assessment_insights']['strengths']}
        - Injury Risk: {kwargs['assessment_insights']['injury_risk']}

        AVAILABLE EQUIPMENT:
        {', '.join(kwargs['available_equipment'])}

        RECENT WORKOUTS:
        {self._format_workout_history(kwargs['previous_workouts'])}

        Generate a 45-minute workout in JSON format with:
        1. Warm-up (5 min)
        2. Technique drills (15 min) - focus on weaknesses
        3. Conditioning (15 min)
        4. Cool-down (5 min)
        5. Specific corrections for identified issues

        Include equipment, reps/duration, rest periods, and coaching cues.
        """

# app/services/biomechanics_analyzer.py
class BiomechanicsAnalyzer:
    """Analyze pose data for boxing-specific metrics"""

    def analyze_stance_quality(self, poses: List[PoseData]) -> float:
        """
        Analyze stance quality (0-100 score)
        - Foot positioning
        - Hip rotation
        - Weight distribution
        """
        scores = []
        for pose in poses:
            foot_width = self._calculate_foot_width(pose)
            hip_angle = self._calculate_hip_rotation(pose)
            balance = self._calculate_center_of_mass(pose)

            score = (
                self._score_foot_positioning(foot_width) * 0.4 +
                self._score_hip_rotation(hip_angle) * 0.3 +
                self._score_balance(balance) * 0.3
            )
            scores.append(score)

        return np.mean(scores)

    def analyze_guard_position(self, poses: List[PoseData]) -> Dict:
        """
        Analyze defensive guard quality
        """
        guard_metrics = {
            'hands_up_percentage': 0,
            'chin_protection': 0,
            'elbow_position': 0,
            'consistency_score': 0
        }

        for pose in poses:
            # Extract key landmarks
            left_wrist = pose.landmarks[15]
            right_wrist = pose.landmarks[16]
            nose = pose.landmarks[0]
            shoulders = (pose.landmarks[11] + pose.landmarks[12]) / 2

            # Check if hands are up (near chin level)
            hands_up = (
                left_wrist.y < nose.y and
                right_wrist.y < nose.y
            )
            guard_metrics['hands_up_percentage'] += hands_up

            # More biomechanical calculations...

        # Calculate percentages
        total_frames = len(poses)
        guard_metrics['hands_up_percentage'] = (
            guard_metrics['hands_up_percentage'] / total_frames * 100
        )

        return guard_metrics

    def calculate_power_generation(self, poses: List[PoseData]) -> Dict:
        """
        Analyze kinetic chain for power generation
        """
        # Hip rotation velocity
        # Shoulder rotation velocity
        # Arm extension speed
        # Weight transfer timing
        pass

    def detect_injury_risks(self, poses: List[PoseData]) -> List[str]:
        """
        Identify movement patterns that indicate injury risk
        """
        risks = []

        # Check for overextension
        # Check for poor landing mechanics
        # Check for excessive twisting
        # Check for imbalanced loading

        return risks
```

#### 2.3.2 Database Schema

**Technology**: PostgreSQL 15+ (AWS RDS)

```sql
-- Core Tables

-- Gyms (multi-tenant)
CREATE TABLE gyms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    owner_email VARCHAR(255) NOT NULL UNIQUE,
    subscription_tier VARCHAR(50) DEFAULT 'basic',
    max_stations INTEGER DEFAULT 1,
    max_members INTEGER DEFAULT 100,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- Branding
    logo_url VARCHAR(500),
    primary_color VARCHAR(7), -- hex color

    -- Subscription
    stripe_customer_id VARCHAR(255),
    subscription_status VARCHAR(50),
    trial_ends_at TIMESTAMP
);

-- Gym Owners/Staff
CREATE TABLE gym_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID REFERENCES gyms(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50) NOT NULL, -- 'owner', 'trainer', 'staff'
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Members
CREATE TABLE members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID REFERENCES gyms(id) ON DELETE CASCADE,

    -- Personal info
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    date_of_birth DATE,

    -- Member ID (PIN for tablet check-in)
    member_pin VARCHAR(6) UNIQUE,
    qr_code_data VARCHAR(255) UNIQUE,

    -- Profile
    experience_level VARCHAR(50), -- 'beginner', 'intermediate', 'advanced'
    goals TEXT[],
    injuries_or_limitations TEXT[],

    -- Status
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'inactive', 'suspended'
    joined_at TIMESTAMP DEFAULT NOW(),
    last_assessment_at TIMESTAMP,

    -- Preferences
    preferred_workout_duration INTEGER DEFAULT 45, -- minutes

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Assessment Stations
CREATE TABLE assessment_stations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID REFERENCES gyms(id) ON DELETE CASCADE,

    name VARCHAR(100) NOT NULL, -- 'Station 1', 'VIP Station', etc.
    edge_device_id VARCHAR(255) UNIQUE,
    edge_device_ip VARCHAR(45),

    -- Hardware info
    camera_1_serial VARCHAR(255),
    camera_2_serial VARCHAR(255),
    tablet_id VARCHAR(255),

    status VARCHAR(50) DEFAULT 'active', -- 'active', 'maintenance', 'offline'
    last_heartbeat TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Assessments
CREATE TABLE assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID REFERENCES members(id) ON DELETE CASCADE,
    station_id UUID REFERENCES assessment_stations(id),

    -- Raw data storage
    poses_data_url VARCHAR(500), -- S3 URL to compressed pose data
    video_thumbnail_url VARCHAR(500),

    -- Computed metrics (denormalized for fast queries)
    stance_quality_score DECIMAL(5,2),
    guard_position_score DECIMAL(5,2),
    movement_speed_score DECIMAL(5,2),
    balance_score DECIMAL(5,2),
    power_generation_score DECIMAL(5,2),
    overall_score DECIMAL(5,2),

    -- Detailed analysis
    biomechanics_analysis JSONB, -- detailed metrics
    strengths TEXT[],
    weaknesses TEXT[],
    injury_risks TEXT[],

    -- Metadata
    duration_seconds INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Workouts
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID REFERENCES members(id) ON DELETE CASCADE,
    assessment_id UUID REFERENCES assessments(id),

    -- Workout structure (JSON for flexibility)
    workout_json JSONB NOT NULL,
    /*
    Example structure:
    {
        "total_duration": 45,
        "sections": [
            {
                "name": "Warm-up",
                "duration": 5,
                "exercises": [
                    {
                        "name": "Jump Rope",
                        "equipment": "jump_rope",
                        "duration": 180,
                        "coaching_cues": ["Light on feet", "Steady rhythm"]
                    }
                ]
            },
            ...
        ],
        "focus_areas": ["defensive guard", "footwork"],
        "equipment_needed": ["heavy_bag", "speed_bag", "jump_rope"]
    }
    */

    -- Completion tracking
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'skipped'
    started_at TIMESTAMP,
    completed_at TIMESTAMP,

    -- Feedback
    member_rating INTEGER, -- 1-5 stars
    member_feedback TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

-- Equipment Inventory
CREATE TABLE gym_equipment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gym_id UUID REFERENCES gyms(id) ON DELETE CASCADE,

    equipment_type VARCHAR(100) NOT NULL, -- 'heavy_bag', 'speed_bag', 'double_end_bag', etc.
    quantity INTEGER DEFAULT 1,
    location_description VARCHAR(255), -- 'North wall', 'Center ring', etc.

    status VARCHAR(50) DEFAULT 'available', -- 'available', 'maintenance', 'unavailable'

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Analytics Events (for tracking)
CREATE TABLE analytics_events (
    id BIGSERIAL PRIMARY KEY,
    gym_id UUID REFERENCES gyms(id) ON DELETE CASCADE,
    member_id UUID REFERENCES members(id) ON DELETE SET NULL,

    event_type VARCHAR(100) NOT NULL, -- 'assessment_completed', 'workout_started', etc.
    event_data JSONB,

    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_members_gym_id ON members(gym_id);
CREATE INDEX idx_members_pin ON members(member_pin);
CREATE INDEX idx_assessments_member_id ON assessments(member_id);
CREATE INDEX idx_assessments_created_at ON assessments(created_at DESC);
CREATE INDEX idx_workouts_member_id ON workouts(member_id);
CREATE INDEX idx_workouts_status ON workouts(status);
CREATE INDEX idx_analytics_gym_id_created ON analytics_events(gym_id, created_at DESC);
```

#### 2.3.3 API Endpoints

**Base URL**: `https://api.gideonboxing.ai/v1`

```python
# app/main.py
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.routers import assessments, workouts, members, gyms, analytics
from app.auth import get_current_user, get_current_gym

app = FastAPI(
    title="GideonBoxingAI API",
    version="1.0.0",
    description="AI-powered boxing assessment and workout generation"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(assessments.router, prefix="/assessments", tags=["Assessments"])
app.include_router(workouts.router, prefix="/workouts", tags=["Workouts"])
app.include_router(members.router, prefix="/members", tags=["Members"])
app.include_router(gyms.router, prefix="/gyms", tags=["Gyms"])
app.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])

# app/routers/assessments.py
from fastapi import APIRouter, Depends, HTTPException
from app.schemas import AssessmentCreate, AssessmentResponse
from app.services.biomechanics_analyzer import BiomechanicsAnalyzer
from app.auth import verify_station_token

router = APIRouter()

@router.post("/", response_model=AssessmentResponse)
async def create_assessment(
    assessment_data: AssessmentCreate,
    station = Depends(verify_station_token)
):
    """
    Receive assessment data from edge device
    Called after edge completes local processing
    """
    # 1. Store raw pose data in S3
    poses_url = await upload_to_s3(
        data=assessment_data.poses,
        bucket="gideon-assessments",
        key=f"{assessment_data.member_id}/{uuid4()}.json.gz"
    )

    # 2. Deep biomechanical analysis
    analyzer = BiomechanicsAnalyzer()
    analysis = await analyzer.deep_analysis(assessment_data.poses)

    # 3. Save to database
    assessment = await Assessment.create(
        member_id=assessment_data.member_id,
        station_id=station.id,
        poses_data_url=poses_url,
        **analysis
    )

    # 4. Trigger workout generation (async)
    from app.tasks import generate_workout_task
    generate_workout_task.delay(assessment.id)

    return assessment

@router.get("/{assessment_id}", response_model=AssessmentResponse)
async def get_assessment(
    assessment_id: str,
    current_user = Depends(get_current_user)
):
    """Get assessment details"""
    assessment = await Assessment.get(assessment_id)

    # Verify access (member can only see their own, gym staff can see all)
    if not current_user.can_access_assessment(assessment):
        raise HTTPException(status_code=403, detail="Access denied")

    return assessment

@router.get("/member/{member_id}/history")
async def get_member_assessment_history(
    member_id: str,
    limit: int = 10,
    current_user = Depends(get_current_user)
):
    """Get assessment history for progress tracking"""
    assessments = await Assessment.query(
        member_id=member_id,
        order_by="created_at DESC",
        limit=limit
    )

    return {
        "assessments": assessments,
        "progress_summary": calculate_progress(assessments)
    }

# app/routers/workouts.py
from fastapi import APIRouter, Depends
from app.schemas import WorkoutResponse
from app.services.workout_generator import WorkoutGeneratorService

router = APIRouter()

@router.get("/{workout_id}", response_model=WorkoutResponse)
async def get_workout(workout_id: str):
    """
    Get workout details for display on tablet
    """
    workout = await Workout.get(workout_id)

    # Include member info for personalization
    member = await Member.get(workout.member_id)

    # Include equipment locations
    gym_equipment = await GymEquipment.get_by_gym(member.gym_id)

    return {
        "workout": workout,
        "member": member,
        "equipment_map": gym_equipment
    }

@router.post("/{workout_id}/start")
async def start_workout(workout_id: str):
    """Mark workout as started"""
    workout = await Workout.get(workout_id)
    workout.status = "in_progress"
    workout.started_at = datetime.utcnow()
    await workout.save()

    # Track analytics
    await track_event("workout_started", workout_id=workout_id)

    return {"status": "started"}

@router.post("/{workout_id}/complete")
async def complete_workout(
    workout_id: str,
    rating: int = None,
    feedback: str = None
):
    """Mark workout as completed with optional feedback"""
    workout = await Workout.get(workout_id)
    workout.status = "completed"
    workout.completed_at = datetime.utcnow()
    workout.member_rating = rating
    workout.member_feedback = feedback
    await workout.save()

    # Track analytics
    await track_event("workout_completed",
                     workout_id=workout_id,
                     rating=rating)

    return {"status": "completed"}

# app/routers/members.py
from fastapi import APIRouter, Depends
from app.schemas import MemberCreate, MemberUpdate, MemberResponse

router = APIRouter()

@router.post("/checkin")
async def member_checkin(pin: str = None, qr_code: str = None):
    """
    Tablet check-in endpoint
    Returns member info if authenticated
    """
    if pin:
        member = await Member.get_by_pin(pin)
    elif qr_code:
        member = await Member.get_by_qr_code(qr_code)
    else:
        raise HTTPException(status_code=400, detail="PIN or QR code required")

    if not member or member.status != 'active':
        raise HTTPException(status_code=404, detail="Member not found or inactive")

    # Track check-in
    await track_event("member_checkin", member_id=member.id)

    return {
        "member": member,
        "last_assessment": await member.get_last_assessment(),
        "next_recommended_assessment": member.last_assessment_at + timedelta(days=7)
    }

@router.get("/{member_id}/dashboard")
async def member_dashboard(member_id: str):
    """
    Member progress dashboard data
    """
    member = await Member.get(member_id)
    assessments = await Assessment.get_by_member(member_id, limit=10)
    workouts = await Workout.get_by_member(member_id, limit=20)

    return {
        "member": member,
        "stats": {
            "total_assessments": len(assessments),
            "total_workouts": len(workouts),
            "completion_rate": calculate_completion_rate(workouts),
            "average_rating": calculate_average_rating(workouts),
            "current_streak": calculate_streak(workouts)
        },
        "progress_chart": generate_progress_chart(assessments),
        "recent_workouts": workouts[:5]
    }
```

### 2.4 Gym Owner Dashboard

**Purpose**: Gym management, member analytics, revenue tracking

**Technology**: Next.js 14+ (React) with TypeScript

**Key Features**:

1. **Member Management**
   - Add/edit/deactivate members
   - View member profiles and progress
   - Export member data

2. **Analytics Dashboard**
   - Daily/weekly/monthly usage stats
   - Member engagement metrics
   - Assessment completion rates
   - Popular workout types

3. **Equipment Management**
   - Equipment inventory
   - Maintenance scheduling
   - Availability status

4. **Station Management**
   - Monitor station health
   - View live usage
   - Configure station settings

5. **Billing & Subscription**
   - Current subscription tier
   - Usage vs. limits
   - Upgrade options
   - Payment history

**Screen Structure**:
```typescript
// pages/dashboard/index.tsx
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { StatsCards } from '@/components/dashboard/StatsCards';
import { UsageChart } from '@/components/dashboard/UsageChart';
import { RecentActivity } from '@/components/dashboard/RecentActivity';

export default function DashboardPage() {
  const { data: stats } = useQuery({
    queryKey: ['gym-stats'],
    queryFn: () => fetch('/api/gyms/stats').then(r => r.json())
  });

  return (
    <DashboardLayout>
      <h1>Gym Dashboard</h1>

      <StatsCards
        totalMembers={stats?.totalMembers}
        activeToday={stats?.activeToday}
        assessmentsThisWeek={stats?.assessmentsThisWeek}
        avgMemberRating={stats?.avgMemberRating}
      />

      <UsageChart data={stats?.usageByDay} />

      <RecentActivity activities={stats?.recentActivities} />
    </DashboardLayout>
  );
}

// components/dashboard/StatsCards.tsx
export const StatsCards: React.FC<Props> = ({
  totalMembers,
  activeToday,
  assessmentsThisWeek,
  avgMemberRating
}) => {
  return (
    <div className="grid grid-cols-4 gap-4 mb-8">
      <StatCard
        title="Total Members"
        value={totalMembers}
        icon={<UsersIcon />}
        trend="+12%"
      />
      <StatCard
        title="Active Today"
        value={activeToday}
        icon={<ActivityIcon />}
        trend="+5%"
      />
      <StatCard
        title="Assessments This Week"
        value={assessmentsThisWeek}
        icon={<ClipboardIcon />}
        trend="+18%"
      />
      <StatCard
        title="Avg. Member Rating"
        value={`${avgMemberRating.toFixed(1)}/5.0`}
        icon={<StarIcon />}
        trend="+0.3"
      />
    </div>
  );
};
```

---

## 3. Technology Stack

### 3.1 Edge (Assessment Station)

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Operating System** | Ubuntu 20.04 LTS | Stable, well-supported for Jetson |
| **Runtime** | Python 3.9+ | Ecosystem for CV and ML |
| **Pose Estimation** | MediaPipe (BlazePose) | Fast, accurate, runs on edge GPU |
| **Video Processing** | OpenCV 4.8+ | Industry standard, CUDA support |
| **Model Acceleration** | TensorRT | Nvidia optimization for Jetson |
| **API Server** | FastAPI | High performance async Python |
| **Container** | Docker | Reproducible deployments |
| **Process Manager** | systemd | Reliable service management |
| **Monitoring** | Prometheus Node Exporter | System metrics |

### 3.2 Tablet Interface

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Framework** | React Native 0.73+ | Cross-platform iOS/Android |
| **Language** | TypeScript | Type safety, better DX |
| **State Management** | Redux Toolkit | Predictable state, dev tools |
| **Navigation** | React Navigation 6+ | Native navigation feel |
| **HTTP Client** | Axios | Retry logic, interceptors |
| **Real-time** | WebSocket (ws library) | Live assessment streaming |
| **Offline Storage** | SQLite (expo-sqlite) | Offline capability |
| **UI Components** | React Native Paper | Material Design |
| **Video Player** | expo-av | Video demonstrations |

### 3.3 Cloud Backend

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **API Framework** | FastAPI (Python 3.11+) | Fast, auto-docs, async |
| **Database** | PostgreSQL 15+ (AWS RDS) | JSONB support, reliable |
| **Object Storage** | AWS S3 | Scalable, cost-effective |
| **Caching** | Redis (ElastiCache) | Session management, rate limiting |
| **Task Queue** | Celery + Redis | Background job processing |
| **AI/ML** | OpenAI GPT-4 API | Workout generation |
| **Auth** | JWT + bcrypt | Stateless auth |
| **ORM** | SQLAlchemy 2.0 | Async support, type hints |
| **Migrations** | Alembic | Database version control |
| **Monitoring** | DataDog / CloudWatch | Application monitoring |
| **Logging** | Structured logging (JSON) | Easy querying |

### 3.4 Gym Owner Dashboard

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Framework** | Next.js 14+ (App Router) | SSR, optimized builds |
| **Language** | TypeScript | Type safety |
| **Styling** | Tailwind CSS | Rapid UI development |
| **UI Library** | shadcn/ui | Beautiful components |
| **Charts** | Recharts | React-friendly charts |
| **Data Fetching** | TanStack Query (React Query) | Cache management, optimistic updates |
| **Forms** | React Hook Form + Zod | Validation, type safety |
| **Auth** | NextAuth.js | Gym owner authentication |
| **Deployment** | Vercel | Easy Next.js hosting |

### 3.5 DevOps & Infrastructure

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Cloud Provider** | AWS | Comprehensive services |
| **Compute** | ECS Fargate | Serverless containers |
| **CDN** | CloudFront | Global edge network |
| **DNS** | Route 53 | AWS integration |
| **CI/CD** | GitHub Actions | Free, integrated with GitHub |
| **IaC** | Terraform | Infrastructure as code |
| **Secrets** | AWS Secrets Manager | Secure credential storage |
| **Monitoring** | DataDog + CloudWatch | Comprehensive observability |
| **Error Tracking** | Sentry | Real-time error alerts |

---

## 4. Data Flow Architecture

### 4.1 Complete Assessment Flow

```
┌──────────────────────────────────────────────────────────────────┐
│ STEP 1: MEMBER CHECK-IN (Tablet)                                │
│                                                                  │
│  Member → Enter PIN/Scan QR → Tablet calls API                  │
│           POST /api/members/checkin                              │
│           Returns: Member profile, last assessment date          │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ STEP 2: ASSESSMENT INSTRUCTIONS (Tablet)                        │
│                                                                  │
│  Display:                                                        │
│  - "Stand in marked area"                                        │
│  - "Face camera 1, camera 2 should see your side"               │
│  - "Perform shadowboxing for 60 seconds"                        │
│  - "GO" button when ready                                       │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ STEP 3: LIVE ASSESSMENT (Edge + Tablet)                         │
│                                                                  │
│  Edge Device:                                                    │
│  1. Start synchronized camera capture (60s)                     │
│  2. MediaPipe pose extraction per frame                         │
│  3. Calculate basic metrics (stance, guard, speed)              │
│  4. Stream to tablet via WebSocket                              │
│                                                                  │
│  Tablet:                                                         │
│  1. Display pose overlay on camera feed                         │
│  2. Show live metrics (hands up: 85%, stance: good)             │
│  3. Display instant feedback ("Keep hands up!")                 │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ STEP 4: CLOUD ANALYSIS (Edge → Cloud API)                       │
│                                                                  │
│  Edge → Cloud:                                                   │
│  POST /api/assessments                                           │
│  Body:                                                           │
│  {                                                               │
│    "member_id": "uuid",                                          │
│    "station_id": "uuid",                                         │
│    "poses": [compressed pose data],                             │
│    "basic_metrics": {...},                                       │
│    "duration_seconds": 60,                                       │
│    "video_thumbnail": "base64..."                                │
│  }                                                               │
│                                                                  │
│  Cloud Backend:                                                  │
│  1. Upload poses to S3                                           │
│  2. Deep biomechanical analysis:                                 │
│     - Joint angles over time                                     │
│     - Power generation (kinetic chain)                           │
│     - Balance analysis                                           │
│     - Injury risk detection                                      │
│  3. Identify strengths and weaknesses                            │
│  4. Save assessment to PostgreSQL                                │
│  5. Trigger async workout generation task                       │
│                                                                  │
│  Returns to Edge:                                                │
│  {                                                               │
│    "assessment_id": "uuid",                                      │
│    "overall_score": 72,                                          │
│    "breakdown": {...},                                           │
│    "status": "processing_workout"                                │
│  }                                                               │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ STEP 5: WORKOUT GENERATION (Cloud Background Task)              │
│                                                                  │
│  Celery Task (async):                                            │
│  1. Fetch assessment data                                        │
│  2. Fetch member profile (goals, limitations, history)           │
│  3. Fetch gym equipment inventory                                │
│  4. Build GPT-4 prompt with all context                          │
│  5. Call OpenAI API for workout generation                       │
│  6. Parse and validate workout JSON                              │
│  7. Save workout to database                                     │
│  8. Notify tablet (WebSocket or polling)                         │
│                                                                  │
│  Typical generation time: 5-10 seconds                           │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ STEP 6: WORKOUT DISPLAY (Tablet)                                │
│                                                                  │
│  Tablet polls: GET /api/assessments/{id}                         │
│  Until status = "workout_ready"                                  │
│                                                                  │
│  Display:                                                        │
│  1. Assessment Results Screen:                                   │
│     - Overall score with visual gauge                            │
│     - Strengths highlighted in green                             │
│     - Weaknesses highlighted in orange                           │
│     - Key metrics breakdown                                      │
│                                                                  │
│  2. Personalized Workout Screen:                                 │
│     - "Your Custom Workout"                                      │
│     - Total duration: 45 min                                     │
│     - Equipment needed (with gym map)                            │
│     - Section-by-section breakdown                               │
│     - Video demos for each exercise                              │
│     - "Start Workout" button                                     │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ STEP 7: WORKOUT EXECUTION (Tablet)                              │
│                                                                  │
│  Member taps "Start Workout"                                     │
│  → POST /api/workouts/{id}/start                                 │
│                                                                  │
│  Tablet guides through each section:                             │
│  - Exercise name and demo video                                  │
│  - Timer for duration                                            │
│  - Coaching cues displayed                                       │
│  - "Next Exercise" button                                        │
│                                                                  │
│  On completion:                                                  │
│  → POST /api/workouts/{id}/complete                              │
│  → Request rating (1-5 stars)                                    │
│  → Optional text feedback                                        │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│ STEP 8: ANALYTICS & INSIGHTS (Cloud)                            │
│                                                                  │
│  Background processing:                                          │
│  - Update member progress metrics                                │
│  - Calculate trend analysis                                      │
│  - Generate insights for gym owner dashboard                     │
│  - Train recommendation model (Phase 2)                          │
│                                                                  │
│  Gym Owner Dashboard:                                            │
│  - Real-time usage stats                                         │
│  - Member engagement trends                                      │
│  - Popular equipment/workouts                                    │
│  - Revenue metrics (member retention)                            │
└──────────────────────────────────────────────────────────────────┘
```

### 4.2 Data Flow Diagram (Technical)

```
┌─────────────────────┐
│   TABLET (React)    │
│                     │
│  1. Check-in        │──────┐
│  2. Instructions    │      │ POST /api/members/checkin
│  8. Workout display │      │ GET /api/workouts/{id}
└──────────┬──────────┘      │
           │                 │
           │ WebSocket       │ HTTPS
           │ (live feed)     │
           │                 │
           ▼                 ▼
┌─────────────────────────────────────┐
│   EDGE DEVICE (Jetson + FastAPI)    │
│                                     │
│  3. Camera capture (60s)            │
│  4. MediaPipe pose extraction       │
│  5. Basic metrics calculation       │
│  6. Compress & upload to cloud      │
└─────────────┬───────────────────────┘
              │
              │ POST /api/assessments
              │ {poses, metrics, thumbnail}
              │
              ▼
┌──────────────────────────────────────────────┐
│     CLOUD BACKEND (FastAPI + AWS)            │
│                                              │
│  ┌────────────────────────────────────┐     │
│  │  API Layer (FastAPI)               │     │
│  │  - Receive assessment data         │     │
│  │  - Authenticate requests           │     │
│  │  - Return workout data             │     │
│  └────────┬──────────────────┬────────┘     │
│           │                  │               │
│           │                  │               │
│  ┌────────▼─────────┐  ┌────▼──────────┐    │
│  │  S3 Storage      │  │  PostgreSQL   │    │
│  │  - Pose data     │  │  - Members    │    │
│  │  - Thumbnails    │  │  - Assessments│    │
│  └──────────────────┘  │  - Workouts   │    │
│                        └───────────────┘    │
│                                              │
│  ┌────────────────────────────────────┐     │
│  │  Background Tasks (Celery)         │     │
│  │                                    │     │
│  │  7. Biomechanics Analysis          │     │
│  │     - Joint angle calculation      │     │
│  │     - Power generation metrics     │     │
│  │     - Injury risk detection        │     │
│  │                                    │     │
│  │  8. Workout Generation (GPT-4)     │     │
│  │     - Fetch member context         │     │
│  │     - Build AI prompt              │     │
│  │     - Generate workout JSON        │     │
│  │     - Save to database             │     │
│  └────────────────────────────────────┘     │
└──────────────────────────────────────────────┘
              │
              │ GET /api/gyms/stats
              │
              ▼
┌─────────────────────────────────┐
│  GYM OWNER DASHBOARD (Next.js)  │
│                                 │
│  - Member management            │
│  - Usage analytics              │
│  - Equipment tracking           │
│  - Billing & subscription       │
└─────────────────────────────────┘
```

---

## 5. MVP Development Roadmap

### 5.1 Overview

**Total Timeline**: 6 months
**Team Size**: 3-5 developers
**Phases**: 2 major phases

### 5.2 Phase 1: Core MVP (Months 1-3)

**Goal**: Single gym deployment with core functionality

#### Month 1: Foundation & Edge System

**Week 1-2: Project Setup**
- [ ] Infrastructure setup (AWS accounts, domains, CI/CD)
- [ ] Repository structure and dev environment
- [ ] Database schema implementation
- [ ] Edge device prototype (Jetson + MediaPipe)
- [ ] Basic FastAPI backend skeleton

**Week 3-4: Assessment Station MVP**
- [ ] Dual camera capture and synchronization
- [ ] MediaPipe integration for pose estimation
- [ ] Basic biomechanics metrics (stance, guard)
- [ ] Edge API server (FastAPI)
- [ ] Local video storage and compression

**Deliverable**: Working assessment station that captures and analyzes shadowboxing

#### Month 2: Cloud Backend & Tablet Interface

**Week 5-6: Backend API**
- [ ] Cloud API implementation (FastAPI)
- [ ] PostgreSQL database deployment (RDS)
- [ ] S3 integration for pose data storage
- [ ] Authentication system (JWT)
- [ ] Basic biomechanics analysis service

**Week 7-8: Tablet Application**
- [ ] React Native project setup
- [ ] Member check-in flow (PIN-based)
- [ ] Live assessment viewer (WebSocket)
- [ ] Assessment results display
- [ ] Basic workout display screen

**Deliverable**: End-to-end flow from check-in → assessment → results

#### Month 3: Workout Generation & Polish

**Week 9-10: AI Workout Generation**
- [ ] GPT-4 integration
- [ ] Workout prompt engineering
- [ ] Workout JSON schema design
- [ ] Background task system (Celery)
- [ ] Workout display with video demos

**Week 11-12: Testing & First Gym Pilot**
- [ ] Hardware installation at pilot gym
- [ ] User testing with real members
- [ ] Bug fixes and UX improvements
- [ ] Performance optimization
- [ ] Basic analytics dashboard for gym owner

**Deliverable**: Complete system running at 1 pilot gym

### 5.3 Phase 2: Scale & Enhance (Months 4-6)

**Goal**: Multi-gym deployment with enhanced features

#### Month 4: Multi-Tenant & Dashboard

**Week 13-14: Multi-Tenant Architecture**
- [ ] Gym onboarding flow
- [ ] Multi-gym database isolation
- [ ] Station provisioning system
- [ ] Gym-specific branding (logos, colors)

**Week 15-16: Gym Owner Dashboard**
- [ ] Next.js dashboard setup
- [ ] Member management UI
- [ ] Analytics and reporting
- [ ] Equipment inventory management
- [ ] Billing integration (Stripe)

**Deliverable**: Self-service gym onboarding + owner dashboard

#### Month 5: Enhanced Features

**Week 17-18: Advanced Analytics**
- [ ] Progress tracking charts
- [ ] Strength/weakness trending
- [ ] Member engagement metrics
- [ ] Automated reporting for gym owners
- [ ] Export capabilities (CSV, PDF)

**Week 19-20: Improved Assessments**
- [ ] Enhanced biomechanics (joint angles, velocities)
- [ ] Injury risk prediction model
- [ ] Video thumbnail generation
- [ ] Assessment comparison tool
- [ ] Recommended re-assessment timing

**Deliverable**: Production-ready features for 5-10 gyms

#### Month 6: Scale & Optimization

**Week 21-22: Performance & Reliability**
- [ ] Load testing and optimization
- [ ] Error handling and retry logic
- [ ] Monitoring and alerting (DataDog)
- [ ] Automated backups
- [ ] Disaster recovery plan

**Week 23-24: Deployment & Marketing**
- [ ] Deploy to 5 beta gyms
- [ ] Collect user feedback
- [ ] Marketing materials (demo videos)
- [ ] Sales documentation
- [ ] Pricing finalization

**Deliverable**: System running at 5+ gyms, ready for wider sales

### 5.4 What to Defer to Phase 2 (Post-MVP)

**Advanced AI Features**:
- Custom ML models (replace MediaPipe)
- Fight outcome prediction
- Sparring partner matching
- Personalized coaching avatars

**Enhanced Hardware**:
- Depth cameras (3D pose estimation)
- Impact sensors on bags
- Heart rate monitor integration
- Smart gloves with sensors

**Mobile App**:
- iOS/Android app for members
- At-home workout tracking
- Social features (leaderboards)
- Video recording at home

**Advanced Business Features**:
- White-label reseller program
- Franchise management tools
- API for third-party integrations
- Advanced billing (usage-based pricing)

**International Expansion**:
- Multi-language support
- Regional data compliance (GDPR, etc.)
- Currency localization
- Timezone handling

---

## 6. Hardware Requirements

### 6.1 Assessment Station Bill of Materials (BOM)

| Component | Model | Quantity | Unit Cost | Total | Notes |
|-----------|-------|----------|-----------|-------|-------|
| **Cameras** | Logitech Brio 4K | 2 | $200 | $400 | 1080p@30fps, USB 3.0, auto-focus |
| **Edge Computer** | Nvidia Jetson Orin Nano 8GB | 1 | $499 | $499 | GPU for MediaPipe, compact |
| **Storage** | Samsung 512GB NVMe SSD | 1 | $60 | $60 | Fast local storage |
| **Power Supply** | Anker 65W USB-C | 1 | $45 | $45 | Power for Jetson |
| **Camera Mounts** | Manfrotto Tripod + Heads | 2 | $150 | $300 | Adjustable, stable |
| **Cables** | USB 3.0 cables (10ft) | 2 | $15 | $30 | Camera to Jetson |
| **Enclosure** | Custom Jetson case | 1 | $50 | $50 | Protection, cooling |
| **Tablet** | iPad 10.2" (2021) 64GB | 1 | $329 | $329 | Member interface |
| **Tablet Mount** | iPad wall mount + charger | 1 | $80 | $80 | Secure mounting |
| **Floor Markers** | Vinyl floor decals | 1 set | $20 | $20 | Position guidance |
| **Signage** | Assessment station sign | 1 | $30 | $30 | Branding, instructions |
| **Installation** | Labor (4 hours) | 1 | $200 | $200 | Professional setup |

**Total Cost Per Station**: **$2,043**

**Alternative Budget Option** (using cheaper components):
- Replace Jetson Orin with Raspberry Pi 5 + Google Coral TPU: ~$150 (may be slower)
- Use 1080p webcams instead of Brio: ~$60 each
- Android tablet instead of iPad: ~$150
- **Budget Total**: ~$1,200 per station

### 6.2 Hardware Specifications Detail

#### 6.2.1 Camera Requirements

**Minimum Specs**:
- Resolution: 1920x1080 (1080p)
- Frame Rate: 30 fps (60 fps preferred for fast movements)
- Field of View: 78° diagonal minimum
- Auto-focus: Required
- Low-light performance: Good (gym lighting varies)
- Connection: USB 3.0 (bandwidth for dual cameras)

**Recommended Models**:
1. **Logitech Brio 4K** ($200) - Best quality, HDR, 90° FOV
2. **Logitech C920** ($70) - Budget option, reliable
3. **Razer Kiyo Pro** ($150) - Good low-light, wide FOV

**Camera Positioning**:
```
Top View:

     [Camera 2] ←── 8 ft ──→
         │
         │ 90°
         │
         └─────┐
               │
        [Member Position]
               │
               │ 0°
               │
               ▼
          [Camera 1]
```

Side View:
```
Wall
 │
 │  [Camera 1/2 at 5 ft height]
 │      │
 │      │ 8 ft
 │      ▼
 │  [Member at 5.5 ft avg height]
 │      │
 ─┴──────┴─ Floor
```

#### 6.2.2 Edge Compute Options

**Option 1: Nvidia Jetson Orin Nano 8GB** (Recommended)
- **CPU**: 6-core ARM Cortex-A78AE
- **GPU**: 1024-core NVIDIA Ampere with 32 Tensor Cores
- **Memory**: 8GB LPDDR5
- **Storage**: NVMe SSD slot
- **Performance**: ~40 TOPS AI performance
- **Power**: 7-15W
- **Cost**: $499
- **Pros**: Best performance, TensorRT support, proven for CV
- **Cons**: Higher cost

**Option 2: Raspberry Pi 5 + Google Coral TPU** (Budget)
- **CPU**: Quad-core ARM Cortex-A76
- **TPU**: Google Coral (4 TOPS)
- **Memory**: 8GB LPDDR4X
- **Cost**: ~$150 total
- **Pros**: Much cheaper
- **Cons**: Lower performance, more DIY setup

**Option 3: Intel NUC 11** (Alternative)
- **CPU**: Intel i5-1135G7
- **GPU**: Intel Iris Xe
- **Memory**: 16GB DDR4
- **Cost**: ~$600
- **Pros**: x86 compatibility, easier software setup
- **Cons**: Higher power consumption, larger form factor

**Recommendation**: Start with Jetson Orin Nano for pilot, evaluate budget option for scale.

#### 6.2.3 Tablet Requirements

**Minimum Specs**:
- Screen: 10" minimum, 1920x1200 resolution
- RAM: 4GB minimum
- Storage: 32GB minimum
- WiFi: 802.11ac or better
- Battery: 8+ hours (wall-powered most of the time)

**Recommended Models**:
1. **iPad 10.2" (2021)** - $329, excellent ecosystem, reliable
2. **Samsung Galaxy Tab A8** - $180, good value for Android
3. **Amazon Fire HD 10** - $150, budget option (limited app ecosystem)

**Recommendation**: iPad for consistency and reliability in commercial setting.

### 6.3 Installation Requirements

**Space Requirements**:
- Floor space: 10 ft x 10 ft minimum (assessment zone)
- Clear zone: No obstructions in camera view
- Lighting: Even lighting, no harsh shadows (LED gym lights ideal)
- Power: 2x wall outlets (1 for edge device, 1 for tablet)
- Network: WiFi or Ethernet connection

**Installation Checklist**:
- [ ] Floor markers applied (member position, camera positions)
- [ ] Cameras mounted at correct height and angle
- [ ] Edge device mounted securely with cooling
- [ ] Tablet mounted at 4.5 ft height (accessible for all)
- [ ] All cables organized and secured
- [ ] Power backup (UPS) connected
- [ ] Network connection tested
- [ ] Software installed and configured
- [ ] Calibration performed (camera alignment)
- [ ] Test assessment with staff member

**Maintenance Schedule**:
- **Weekly**: Check camera lenses for smudges/damage
- **Monthly**: Verify camera alignment, test full assessment flow
- **Quarterly**: Software updates, hardware inspection
- **Annually**: Deep clean, replace any worn components

---

## 7. Performance Requirements

### 7.1 MVP Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Assessment Processing Time** | < 90 seconds | Member starts → workout displayed |
| **Real-time Pose Extraction** | 30 fps | No dropped frames during 60s capture |
| **Workout Generation** | < 15 seconds | API call → completed workout |
| **Tablet App Load Time** | < 2 seconds | Check-in screen ready |
| **API Response Time (p95)** | < 500ms | All non-ML endpoints |
| **Edge Device Uptime** | > 99% | Per month |
| **System Accuracy** | > 85% | Pose keypoint detection accuracy |
| **Member Satisfaction** | > 4.0/5.0 | Avg workout rating |

### 7.2 Detailed Performance Specifications

#### 7.2.1 Edge Processing

**Pose Estimation**:
- MediaPipe BlazePose extraction: 30 fps (33ms per frame)
- Total frames per 60s assessment: 1,800 frames
- Processing time: Real-time (complete before video ends)
- Memory usage: < 4GB RAM during processing

**Video Capture**:
- Dual camera synchronization: < 5ms offset
- Video encoding: H.264, 1080p@30fps, ~8 Mbps bitrate
- Storage: ~60 MB per camera per 60s assessment
- Compression: Pose data to < 500 KB per assessment

**Network Upload**:
- Pose data upload to cloud: < 5 seconds on 10 Mbps uplink
- Fallback: Store locally if network unavailable, sync later

#### 7.2.2 Cloud Backend

**Database Performance**:
- Read queries (member lookup, workout fetch): < 50ms
- Write queries (save assessment): < 100ms
- Complex analytics queries: < 2 seconds
- Concurrent connections: 100+ connections per database instance

**API Throughput**:
- Requests per second: 100+ (single instance)
- Concurrent assessments: 20+ simultaneous
- Celery task processing: 10 tasks/second

**Workout Generation**:
- GPT-4 API latency: 5-10 seconds (variable)
- Timeout: 30 seconds max
- Retry logic: 3 attempts with exponential backoff

#### 7.2.3 Scalability Targets

**Year 1**:
- Gyms: 50 gyms
- Stations: 75 total (avg 1.5 per gym)
- Members: 5,000 total (avg 100 per gym)
- Assessments/day: 250 (avg 5 per gym per day)
- Peak load: 50 concurrent assessments

**Infrastructure Sizing for Year 1**:
- API servers: 2-3 ECS tasks (2 vCPU, 4GB RAM each)
- Database: RDS db.t4g.medium (2 vCPU, 4GB RAM)
- Celery workers: 5 workers (2 vCPU, 4GB RAM each)
- S3 storage: ~500 GB (pose data + thumbnails)
- Monthly cost: ~$800-1,200 (excluding GPT-4 API)

### 7.3 Accuracy Targets

**Pose Estimation Accuracy**:
- Keypoint detection: > 85% accuracy (MediaPipe benchmark)
- False positive rate: < 5%
- Occluded joint handling: Graceful degradation

**Biomechanics Analysis**:
- Stance quality scoring: ±10% variation vs. expert trainer
- Guard position detection: > 90% accuracy
- Movement pattern classification: > 80% precision

**Workout Relevance** (based on member feedback):
- Workout addresses weaknesses: > 80% of members agree
- Equipment availability: > 95% accuracy
- Difficulty appropriate: > 75% of members agree

### 7.4 Reliability & Availability

**System Uptime**:
- Cloud API: 99.9% uptime (< 45 min downtime/month)
- Edge devices: 99% uptime (< 7 hours downtime/month)
- Gym owner dashboard: 99.5% uptime

**Error Handling**:
- Network failures: Assessment queued, processed when reconnected
- Hardware failures: Clear error messages, fallback modes
- API rate limits: Exponential backoff, user notification

**Data Integrity**:
- Database backups: Daily automated backups, 30-day retention
- Pose data: S3 versioning enabled, lifecycle policies
- Zero data loss guarantee for completed assessments

**Monitoring & Alerts**:
- Edge device health checks: Every 5 minutes
- API error rate threshold: Alert if > 1% errors in 5 min window
- Workout generation failures: Alert if > 5% failure rate
- On-call rotation: 24/7 support for P0/P1 issues

---

## 8. Project Structure

### 8.1 Repository Organization

```
gideon-boxing-ai/
│
├── edge/                          # Edge device software
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py                    # Entry point
│   ├── config/
│   │   ├── cameras.yaml           # Camera configuration
│   │   └── models.yaml            # Model paths
│   ├── services/
│   │   ├── camera_capture.py      # Dual camera capture
│   │   ├── pose_estimator.py      # MediaPipe integration
│   │   ├── metrics_calculator.py  # Basic biomechanics
│   │   └── cloud_sync.py          # Upload to cloud API
│   ├── api/
│   │   ├── server.py              # FastAPI server
│   │   └── websocket.py           # Real-time streaming
│   ├── utils/
│   │   ├── video_compression.py
│   │   └── logging.py
│   └── tests/
│       ├── test_pose_estimator.py
│       └── test_metrics.py
│
├── backend/                       # Cloud backend API
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── alembic/                   # Database migrations
│   │   ├── versions/
│   │   └── env.py
│   ├── app/
│   │   ├── main.py                # FastAPI app
│   │   ├── config.py              # Settings (env vars)
│   │   ├── database.py            # SQLAlchemy setup
│   │   ├── models/                # Database models
│   │   │   ├── gym.py
│   │   │   ├── member.py
│   │   │   ├── assessment.py
│   │   │   └── workout.py
│   │   ├── schemas/               # Pydantic schemas
│   │   │   ├── assessment.py
│   │   │   ├── workout.py
│   │   │   └── member.py
│   │   ├── routers/               # API endpoints
│   │   │   ├── assessments.py
│   │   │   ├── workouts.py
│   │   │   ├── members.py
│   │   │   ├── gyms.py
│   │   │   └── analytics.py
│   │   ├── services/              # Business logic
│   │   │   ├── biomechanics_analyzer.py
│   │   │   ├── workout_generator.py
│   │   │   ├── progress_tracker.py
│   │   │   └── equipment_manager.py
│   │   ├── auth/                  # Authentication
│   │   │   ├── jwt.py
│   │   │   └── permissions.py
│   │   ├── tasks/                 # Celery tasks
│   │   │   ├── celery_app.py
│   │   │   └── workout_tasks.py
│   │   └── utils/
│   │       ├── s3.py              # S3 helper
│   │       └── openai_client.py
│   └── tests/
│       ├── test_api/
│       ├── test_services/
│       └── conftest.py
│
├── tablet/                        # React Native tablet app
│   ├── package.json
│   ├── app.json                   # Expo config
│   ├── tsconfig.json
│   ├── src/
│   │   ├── App.tsx                # Root component
│   │   ├── navigation/
│   │   │   └── AppNavigator.tsx
│   │   ├── screens/
│   │   │   ├── CheckInScreen.tsx
│   │   │   ├── InstructionsScreen.tsx
│   │   │   ├── AssessmentScreen.tsx
│   │   │   ├── ResultsScreen.tsx
│   │   │   └── WorkoutScreen.tsx
│   │   ├── components/
│   │   │   ├── PoseOverlay.tsx
│   │   │   ├── MetricsPanel.tsx
│   │   │   ├── WorkoutCard.tsx
│   │   │   └── ProgressGauge.tsx
│   │   ├── hooks/
│   │   │   ├── useWebSocket.ts
│   │   │   ├── useApi.ts
│   │   │   └── useOfflineStorage.ts
│   │   ├── store/                 # Redux
│   │   │   ├── store.ts
│   │   │   ├── slices/
│   │   │   │   ├── memberSlice.ts
│   │   │   │   ├── assessmentSlice.ts
│   │   │   │   └── workoutSlice.ts
│   │   ├── services/
│   │   │   └── api.ts             # API client
│   │   ├── types/
│   │   │   ├── Member.ts
│   │   │   ├── Assessment.ts
│   │   │   └── Workout.ts
│   │   └── utils/
│   │       └── formatters.ts
│   └── __tests__/
│
├── dashboard/                     # Gym owner Next.js dashboard
│   ├── package.json
│   ├── tsconfig.json
│   ├── next.config.js
│   ├── src/
│   │   ├── app/                   # Next.js 14 app router
│   │   │   ├── layout.tsx
│   │   │   ├── page.tsx           # Dashboard home
│   │   │   ├── members/
│   │   │   │   ├── page.tsx       # Member list
│   │   │   │   └── [id]/
│   │   │   │       └── page.tsx   # Member detail
│   │   │   ├── analytics/
│   │   │   │   └── page.tsx
│   │   │   ├── equipment/
│   │   │   │   └── page.tsx
│   │   │   ├── stations/
│   │   │   │   └── page.tsx
│   │   │   └── settings/
│   │   │       └── page.tsx
│   │   ├── components/
│   │   │   ├── ui/                # shadcn/ui components
│   │   │   ├── layouts/
│   │   │   │   ├── DashboardLayout.tsx
│   │   │   │   └── Sidebar.tsx
│   │   │   ├── dashboard/
│   │   │   │   ├── StatsCards.tsx
│   │   │   │   ├── UsageChart.tsx
│   │   │   │   └── RecentActivity.tsx
│   │   │   └── members/
│   │   │       ├── MemberTable.tsx
│   │   │       └── MemberForm.tsx
│   │   ├── lib/
│   │   │   ├── api.ts             # API client
│   │   │   └── utils.ts
│   │   └── types/
│   │       └── index.ts
│   └── public/
│
├── infrastructure/                # Infrastructure as Code
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── modules/
│   │   │   ├── networking/
│   │   │   ├── ecs/
│   │   │   ├── rds/
│   │   │   ├── s3/
│   │   │   └── monitoring/
│   │   └── environments/
│   │       ├── dev/
│   │       ├── staging/
│   │       └── production/
│   └── scripts/
│       ├── deploy.sh
│       └── db-migrate.sh
│
├── docs/                          # Documentation
│   ├── API.md                     # API documentation
│   ├── DEPLOYMENT.md              # Deployment guide
│   ├── HARDWARE_SETUP.md          # Hardware installation
│   ├── TROUBLESHOOTING.md
│   └── ARCHITECTURE.md            # This file
│
├── .github/
│   └── workflows/
│       ├── edge-ci.yml            # Edge device CI/CD
│       ├── backend-ci.yml         # Backend API CI/CD
│       ├── tablet-ci.yml          # Tablet app CI/CD
│       └── dashboard-ci.yml       # Dashboard CI/CD
│
├── docker-compose.yml             # Local development
├── .env.example
└── README.md
```

### 8.2 Key Configuration Files

#### Edge Device Config

```yaml
# edge/config/cameras.yaml
cameras:
  front:
    index: 0  # USB device index
    resolution: [1920, 1080]
    fps: 30
    position:
      angle: 0  # degrees from member
      distance: 8  # feet
      height: 5  # feet

  side:
    index: 1
    resolution: [1920, 1080]
    fps: 30
    position:
      angle: 90
      distance: 8
      height: 5

assessment:
  duration_seconds: 60
  sync_tolerance_ms: 5

cloud_api:
  url: https://api.gideonboxing.ai/v1
  timeout_seconds: 30
  retry_attempts: 3
```

#### Backend Environment Variables

```bash
# backend/.env.example

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/gideon
DATABASE_POOL_SIZE=20

# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
S3_BUCKET_ASSESSMENTS=gideon-assessments
S3_BUCKET_MEDIA=gideon-media

# Redis
REDIS_URL=redis://localhost:6379/0

# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4-turbo

# Auth
JWT_SECRET=your-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Monitoring
DATADOG_API_KEY=...
SENTRY_DSN=...

# Feature Flags
ENABLE_WORKOUT_GENERATION=true
ENABLE_ADVANCED_ANALYTICS=false
```

---

## 9. API Specifications

### 9.1 Authentication

All API requests (except public endpoints) require JWT authentication.

**Headers**:
```
Authorization: Bearer <jwt_token>
```

**Token Structure**:
```json
{
  "sub": "user_id",
  "gym_id": "gym_uuid",
  "role": "owner|trainer|station",
  "exp": 1234567890
}
```

### 9.2 Core Endpoints

#### 9.2.1 Member Management

```http
POST /api/members/checkin
```

**Description**: Authenticate member for assessment

**Request**:
```json
{
  "pin": "123456",
  // OR
  "qr_code": "QR_DATA_STRING"
}
```

**Response** (200 OK):
```json
{
  "member": {
    "id": "uuid",
    "first_name": "John",
    "last_name": "Doe",
    "experience_level": "intermediate",
    "goals": ["improve defense", "build endurance"]
  },
  "last_assessment": {
    "id": "uuid",
    "created_at": "2025-10-15T10:30:00Z",
    "overall_score": 72
  },
  "days_since_last_assessment": 8,
  "recommended_next_assessment": "2025-10-22T10:30:00Z"
}
```

---

```http
GET /api/members/{member_id}/dashboard
```

**Description**: Get member progress dashboard

**Response** (200 OK):
```json
{
  "member": { /* member object */ },
  "stats": {
    "total_assessments": 12,
    "total_workouts": 45,
    "completion_rate": 0.89,
    "average_rating": 4.3,
    "current_streak_days": 7
  },
  "progress_chart": [
    {
      "date": "2025-10-01",
      "overall_score": 65,
      "stance_quality": 70,
      "guard_position": 60
    },
    // ...more data points
  ],
  "recent_workouts": [ /* workout objects */ ]
}
```

#### 9.2.2 Assessments

```http
POST /api/assessments
```

**Description**: Submit assessment data from edge device

**Authentication**: Station token required

**Request**:
```json
{
  "member_id": "uuid",
  "station_id": "uuid",
  "duration_seconds": 60,
  "poses": {
    "front_camera": [
      {
        "frame": 0,
        "timestamp": 0.0,
        "landmarks": [
          {"x": 0.5, "y": 0.3, "z": -0.1, "visibility": 0.98},
          // ...33 landmarks total
        ]
      },
      // ...1800 frames
    ],
    "side_camera": [ /* same structure */ ]
  },
  "basic_metrics": {
    "stance_quality_score": 75,
    "guard_position_score": 68,
    "movement_speed_score": 82,
    "balance_score": 71
  },
  "video_thumbnail_base64": "data:image/jpeg;base64,..."
}
```

**Response** (202 Accepted):
```json
{
  "assessment_id": "uuid",
  "status": "processing",
  "estimated_completion_seconds": 15,
  "poll_url": "/api/assessments/uuid"
}
```

---

```http
GET /api/assessments/{assessment_id}
```

**Description**: Get assessment results

**Response** (200 OK):
```json
{
  "id": "uuid",
  "member_id": "uuid",
  "created_at": "2025-10-21T14:30:00Z",
  "status": "completed",

  "scores": {
    "overall": 72,
    "stance_quality": 75,
    "guard_position": 68,
    "movement_speed": 82,
    "balance": 71,
    "power_generation": 65
  },

  "analysis": {
    "strengths": [
      "Excellent footwork and lateral movement",
      "Consistent punching speed",
      "Good balance during combinations"
    ],
    "weaknesses": [
      "Hands drop after punching",
      "Limited hip rotation on power punches",
      "Stance too wide at times"
    ],
    "injury_risks": [
      "Overextension on right cross may strain shoulder"
    ]
  },

  "workout": {
    "id": "uuid",
    "status": "ready",
    "url": "/api/workouts/uuid"
  }
}
```

#### 9.2.3 Workouts

```http
GET /api/workouts/{workout_id}
```

**Description**: Get workout details for display

**Response** (200 OK):
```json
{
  "id": "uuid",
  "member_id": "uuid",
  "assessment_id": "uuid",
  "created_at": "2025-10-21T14:30:15Z",

  "workout": {
    "total_duration_minutes": 45,
    "focus_areas": ["defensive guard", "power generation"],

    "sections": [
      {
        "name": "Warm-up",
        "duration_minutes": 5,
        "exercises": [
          {
            "name": "Jump Rope",
            "equipment": "jump_rope",
            "equipment_location": "Equipment rack near entrance",
            "duration_seconds": 180,
            "sets": null,
            "reps": null,
            "coaching_cues": [
              "Light on your feet",
              "Steady rhythm",
              "Relax your shoulders"
            ],
            "video_demo_url": "https://videos.gideonboxing.ai/jump-rope.mp4"
          },
          {
            "name": "Dynamic Stretching",
            "equipment": null,
            "duration_seconds": 120,
            "coaching_cues": [
              "Arm circles forward and back",
              "Hip rotations",
              "Leg swings"
            ]
          }
        ]
      },
      {
        "name": "Technique Drills",
        "duration_minutes": 15,
        "focus": "Improving guard position and power generation",
        "exercises": [
          {
            "name": "Mirror Shadow Boxing - Guard Focus",
            "equipment": "mirror",
            "equipment_location": "West wall mirrors",
            "duration_seconds": 300,
            "coaching_cues": [
              "Hands up at all times - fix your dropping hands",
              "Chin tucked behind shoulder",
              "Watch your guard in the mirror",
              "Return hands to guard after every punch"
            ]
          },
          {
            "name": "Heavy Bag - Hip Rotation Drill",
            "equipment": "heavy_bag",
            "equipment_location": "Bags 3-5 near center",
            "sets": 3,
            "duration_seconds": 120,
            "rest_seconds": 60,
            "coaching_cues": [
              "Focus on rotating hips before shoulders",
              "Drive power from your legs",
              "Feel the twist in your core",
              "Jab: 30%, Cross: 70% power from hips"
            ]
          }
        ]
      },
      {
        "name": "Conditioning",
        "duration_minutes": 15,
        "exercises": [ /* ... */ ]
      },
      {
        "name": "Cool Down",
        "duration_minutes": 5,
        "exercises": [ /* ... */ ]
      }
    ],

    "equipment_needed": [
      "jump_rope",
      "heavy_bag",
      "speed_bag",
      "focus_mitts"
    ],

    "equipment_map_url": "/api/gyms/{gym_id}/equipment-map"
  },

  "status": "pending",
  "member_rating": null,
  "member_feedback": null
}
```

---

```http
POST /api/workouts/{workout_id}/start
```

**Description**: Mark workout as started

**Response** (200 OK):
```json
{
  "status": "in_progress",
  "started_at": "2025-10-21T14:45:00Z"
}
```

---

```http
POST /api/workouts/{workout_id}/complete
```

**Description**: Mark workout as completed with feedback

**Request**:
```json
{
  "rating": 5,
  "feedback": "Great workout, really felt the focus on guard position!"
}
```

**Response** (200 OK):
```json
{
  "status": "completed",
  "completed_at": "2025-10-21T15:30:00Z",
  "duration_minutes": 45,
  "next_assessment_recommended": "2025-10-28T14:00:00Z"
}
```

#### 9.2.4 Analytics (Gym Owner)

```http
GET /api/gyms/{gym_id}/stats
```

**Description**: Get gym usage statistics

**Query Parameters**:
- `start_date`: ISO date (default: 30 days ago)
- `end_date`: ISO date (default: today)

**Response** (200 OK):
```json
{
  "gym": { /* gym object */ },

  "summary": {
    "total_members": 127,
    "active_members_30d": 89,
    "total_assessments": 456,
    "total_workouts": 1834,
    "avg_member_rating": 4.3,
    "workout_completion_rate": 0.87
  },

  "usage_by_day": [
    {
      "date": "2025-10-01",
      "assessments": 12,
      "workouts": 48,
      "unique_members": 35
    },
    // ...
  ],

  "popular_equipment": [
    {"equipment": "heavy_bag", "usage_count": 890},
    {"equipment": "speed_bag", "usage_count": 567},
    {"equipment": "jump_rope", "usage_count": 1200}
  ],

  "member_engagement": {
    "high_engagement": 45,  // 3+ visits/week
    "medium_engagement": 32,  // 1-2 visits/week
    "low_engagement": 12,  // <1 visit/week
    "inactive": 38  // No activity in 30 days
  },

  "recent_activities": [
    {
      "timestamp": "2025-10-21T14:30:00Z",
      "type": "assessment_completed",
      "member_name": "John Doe",
      "details": "Overall score: 72"
    },
    // ...
  ]
}
```

### 9.3 WebSocket API (Edge → Tablet)

**Endpoint**: `ws://{edge_device_ip}/ws/assessment`

**Connection**:
```javascript
const ws = new WebSocket('ws://192.168.1.100/ws/assessment');

ws.onopen = () => {
  ws.send(JSON.stringify({
    action: 'start_assessment',
    member_id: 'uuid'
  }));
};
```

**Server → Client Messages**:

```json
// Frame update (30 fps)
{
  "type": "frame_update",
  "frame": 450,
  "timestamp": 15.0,
  "pose_overlay": {
    "landmarks": [ /* 33 landmarks for visualization */ ]
  },
  "live_metrics": {
    "stance_quality": 75,
    "hands_up_percentage": 82,
    "current_speed": "moderate"
  },
  "instant_feedback": [
    "Good! Keep hands up",
    "Widen your stance slightly"
  ]
}

// Assessment completed
{
  "type": "assessment_complete",
  "basic_scores": {
    "stance_quality": 75,
    "guard_position": 68,
    "movement_speed": 82
  },
  "status": "uploading_to_cloud"
}

// Cloud processing update
{
  "type": "cloud_processing",
  "status": "generating_workout",
  "progress": 75
}

// Workout ready
{
  "type": "workout_ready",
  "workout_id": "uuid",
  "assessment_id": "uuid"
}
```

---

## 10. Deployment Architecture

### 10.1 AWS Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS CLOUD (US-EAST-1)                   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    CloudFront CDN                        │   │
│  │  - Global edge caching                                   │   │
│  │  - SSL termination                                       │   │
│  └────────────────┬──────────────────┬──────────────────────┘   │
│                   │                  │                          │
│        ┌──────────▼────────┐  ┌──────▼───────────┐             │
│        │   S3 Bucket       │  │  Application     │             │
│        │   (Static Assets) │  │  Load Balancer   │             │
│        │   - Videos        │  │  (ALB)           │             │
│        │   - Images        │  └────────┬─────────┘             │
│        └───────────────────┘           │                        │
│                                        │                        │
│                          ┌─────────────▼──────────────┐         │
│                          │     ECS Fargate Cluster    │         │
│                          │                            │         │
│                          │  ┌──────────────────────┐  │         │
│                          │  │  API Service         │  │         │
│                          │  │  (FastAPI)           │  │         │
│                          │  │  - 2-3 tasks         │  │         │
│                          │  │  - Auto-scaling      │  │         │
│                          │  └──────────┬───────────┘  │         │
│                          │             │              │         │
│                          │  ┌──────────▼───────────┐  │         │
│                          │  │  Celery Workers      │  │         │
│                          │  │  (Background Tasks)  │  │         │
│                          │  │  - 3-5 tasks         │  │         │
│                          │  └──────────────────────┘  │         │
│                          └────────────────────────────┘         │
│                                        │                        │
│               ┌────────────────────────┼──────────────┐         │
│               │                        │              │         │
│     ┌─────────▼────────┐    ┌──────────▼──────┐  ┌───▼─────┐   │
│     │  RDS PostgreSQL  │    │  ElastiCache    │  │   S3    │   │
│     │  (Multi-AZ)      │    │  Redis          │  │  Pose   │   │
│     │  - db.t4g.medium │    │  - cache.t3.med │  │  Data   │   │
│     └──────────────────┘    └─────────────────┘  └─────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │               Monitoring & Logging                       │   │
│  │  - CloudWatch Logs, Metrics, Alarms                     │   │
│  │  - DataDog APM                                           │   │
│  │  - Sentry Error Tracking                                 │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         VERCEL (Dashboard)                      │
│  - Next.js App (Gym Owner Dashboard)                           │
│  - Serverless Functions                                         │
│  - Global CDN                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     GYM LOCATIONS (Edge)                        │
│                                                                 │
│  Each Gym:                                                      │
│  ┌────────────────────────────────────────┐                     │
│  │  Jetson Orin Nano (Edge Device)       │                     │
│  │  - Docker containers                   │                     │
│  │  - Local FastAPI server                │                     │
│  │  - MediaPipe processing                │                     │
│  │  - WiFi/Ethernet → Cloud API           │                     │
│  └────────────────────────────────────────┘                     │
│  ┌────────────────────────────────────────┐                     │
│  │  iPad Tablets                          │                     │
│  │  - React Native app                    │                     │
│  │  - WiFi → Edge device + Cloud API      │                     │
│  └────────────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

### 10.2 Deployment Process

#### 10.2.1 Backend API Deployment

**CI/CD Pipeline** (GitHub Actions):

```yaml
# .github/workflows/backend-ci.yml
name: Backend CI/CD

on:
  push:
    branches: [main, staging]
    paths:
      - 'backend/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          cd backend
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Run tests
        run: |
          cd backend
          pytest tests/ --cov=app --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to ECR
        run: |
          aws ecr get-login-password --region us-east-1 | \
          docker login --username AWS --password-stdin \
          ${{ secrets.ECR_REGISTRY }}

      - name: Build and push Docker image
        run: |
          cd backend
          docker build -t gideon-api:${{ github.sha }} .
          docker tag gideon-api:${{ github.sha }} \
            ${{ secrets.ECR_REGISTRY }}/gideon-api:latest
          docker push ${{ secrets.ECR_REGISTRY }}/gideon-api:latest

      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster gideon-production \
            --service gideon-api \
            --force-new-deployment

      - name: Notify Slack
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "Backend deployed to production successfully!"
            }
```

**Manual Deployment Steps**:

1. **Database Migration**:
   ```bash
   # Run from local machine or bastion host
   cd backend
   alembic upgrade head
   ```

2. **Update Environment Variables**:
   ```bash
   # Update secrets in AWS Secrets Manager
   aws secretsmanager update-secret \
     --secret-id gideon/production/backend \
     --secret-string file://secrets.json
   ```

3. **Deploy New Version**:
   ```bash
   # Trigger via GitHub push to main, or manually:
   aws ecs update-service \
     --cluster gideon-production \
     --service gideon-api \
     --force-new-deployment
   ```

4. **Verify Deployment**:
   ```bash
   # Check service health
   curl https://api.gideonboxing.ai/health

   # Check logs
   aws logs tail /ecs/gideon-api --follow
   ```

#### 10.2.2 Edge Device Deployment

**Initial Setup** (per gym installation):

1. **Flash Jetson with Ubuntu**:
   ```bash
   # On development machine
   sudo sdkmanager --cli install \
     --logintype devzone \
     --product Jetson \
     --target JETSON_ORIN_NANO_TARGETS \
     --flash all
   ```

2. **Install Docker and Dependencies**:
   ```bash
   # SSH into Jetson
   ssh gideon@jetson-gym-001.local

   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh

   # Install Nvidia Container Runtime
   sudo apt-get install -y nvidia-docker2
   sudo systemctl restart docker
   ```

3. **Deploy Edge Software**:
   ```bash
   # Pull Docker image from registry
   docker pull ghcr.io/gideonboxing/edge:latest

   # Run container with GPU support
   docker run -d \
     --name gideon-edge \
     --runtime nvidia \
     --restart unless-stopped \
     -v /data:/data \
     -p 8000:8000 \
     -e CLOUD_API_URL=https://api.gideonboxing.ai/v1 \
     -e STATION_TOKEN=$STATION_TOKEN \
     --device /dev/video0 \
     --device /dev/video1 \
     ghcr.io/gideonboxing/edge:latest
   ```

4. **Configure Cameras**:
   ```bash
   # Test camera access
   v4l2-ctl --list-devices

   # Update camera config
   docker exec gideon-edge vi /app/config/cameras.yaml
   ```

5. **Register Station with Cloud**:
   ```bash
   # Get station provisioning token from dashboard
   # Run provisioning script
   docker exec gideon-edge python /app/scripts/register_station.py \
     --token $PROVISIONING_TOKEN \
     --gym-id $GYM_ID
   ```

**Update Edge Software**:

```bash
# On Jetson
cd /home/gideon/gideon-edge

# Pull latest image
docker pull ghcr.io/gideonboxing/edge:latest

# Stop current container
docker stop gideon-edge
docker rm gideon-edge

# Start new version (same command as initial setup)
./deploy.sh
```

#### 10.2.3 Tablet App Deployment

**Build & Publish** (using Expo EAS):

```bash
cd tablet

# Install EAS CLI
npm install -g eas-cli

# Configure project
eas build:configure

# Build for iOS
eas build --platform ios --profile production

# Build for Android
eas build --platform android --profile production

# Submit to App Store / Play Store
eas submit --platform ios
eas submit --platform android
```

**Over-the-Air Updates** (for minor updates):

```bash
# Publish update without app store review
eas update --branch production --message "Bug fixes and improvements"
```

**Install on Gym Tablets**:

1. Download from App Store / Play Store
2. Configure on first launch:
   - Enter gym code
   - Connect to WiFi
   - Pair with edge device (auto-discover on local network)
3. Enable kiosk mode (tablet management)

### 10.3 Environment Management

**Environments**:

1. **Development**:
   - Local Docker Compose
   - Mock data
   - No real cameras needed (use test videos)

2. **Staging**:
   - AWS staging environment (smaller instances)
   - 1 test gym setup
   - Integration testing

3. **Production**:
   - AWS production environment
   - All live gyms
   - Full monitoring and backups

**Environment Variables**:

```bash
# Development (.env.local)
ENV=development
DATABASE_URL=postgresql://localhost:5432/gideon_dev
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=sk-test-...
AWS_S3_BUCKET=gideon-dev

# Staging (.env.staging)
ENV=staging
DATABASE_URL=postgresql://staging-db.xxx.rds.amazonaws.com:5432/gideon
REDIS_URL=redis://staging-redis.xxx.cache.amazonaws.com:6379
OPENAI_API_KEY=sk-test-...
AWS_S3_BUCKET=gideon-staging

# Production (AWS Secrets Manager)
ENV=production
DATABASE_URL=<from secrets manager>
REDIS_URL=<from secrets manager>
OPENAI_API_KEY=<from secrets manager>
AWS_S3_BUCKET=gideon-production
```

---

## 11. Security & Compliance

### 11.1 Security Measures

**Data Encryption**:
- **In Transit**: TLS 1.3 for all API communication
- **At Rest**:
  - RDS encryption enabled (AES-256)
  - S3 bucket encryption (SSE-S3)
  - Encrypted backups

**Authentication & Authorization**:
- **Members**: PIN (6 digits) or QR code
- **Gym Staff**: Email/password with JWT tokens
- **Edge Devices**: Station-specific tokens (rotated quarterly)
- **API**: JWT with short expiration (24h), refresh tokens

**Network Security**:
- **Cloud**: VPC with private subnets, security groups
- **Edge**: Firewall rules (only necessary ports open)
- **API**: Rate limiting (100 req/min per IP)

**Secrets Management**:
- AWS Secrets Manager for all credentials
- No secrets in code or environment variables
- Automatic secret rotation (database passwords)

**Monitoring & Logging**:
- All API requests logged (CloudWatch)
- Failed authentication attempts tracked
- Anomaly detection (DataDog)
- Security alerts (Slack notifications)

### 11.2 Compliance Considerations

**Data Privacy**:
- **Member Data**: Name, video poses (no actual video stored long-term)
- **Retention**: Pose data retained for 90 days, then archived/deleted
- **GDPR**: Right to erasure implemented (delete member data on request)
- **CCPA**: California privacy rights supported

**HIPAA** (if gyms have medical partnerships):
- Currently not HIPAA compliant
- Phase 2: Add BAA, audit logging, enhanced encryption

**PCI DSS** (for billing):
- Stripe handles all payment processing
- No card data stored in our systems
- Compliance inherited from Stripe

### 11.3 Incident Response Plan

**Severity Levels**:
- **P0**: System down, data breach
- **P1**: Degraded performance, security issue
- **P2**: Minor bug, feature request

**P0 Response**:
1. Alert on-call engineer (PagerDuty)
2. Create incident channel (Slack)
3. Investigate and contain
4. Fix and deploy
5. Post-mortem within 48 hours

---

## 12. Cost Analysis

### 12.1 Per-Gym Hardware Cost

| Item | Cost |
|------|------|
| Assessment Station Hardware | $2,043 |
| Installation (4 hours labor) | $200 |
| **Total per Gym** | **$2,243** |

**Financing Options**:
- Gym pays upfront: $2,243
- Gym pays monthly: $100/month for 24 months
- Gideon leases hardware: $150/month subscription (includes hardware)

### 12.2 Cloud Infrastructure Costs (Monthly)

**Year 1 Projection** (50 gyms, 5,000 members):

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| **AWS ECS Fargate** | 3 API tasks (2 vCPU, 4GB) | $90 |
| **AWS ECS Fargate** | 5 Celery workers (2 vCPU, 4GB) | $150 |
| **RDS PostgreSQL** | db.t4g.medium (Multi-AZ) | $120 |
| **ElastiCache Redis** | cache.t3.medium | $80 |
| **S3 Storage** | 500 GB (pose data) | $12 |
| **S3 Requests** | ~1M requests/month | $5 |
| **CloudFront** | 100 GB data transfer | $10 |
| **Data Transfer** | 200 GB outbound | $18 |
| **CloudWatch** | Logs, metrics, alarms | $30 |
| **Secrets Manager** | 10 secrets | $5 |
| **OpenAI API** | 250 workout generations/day @ $0.10 | $750 |
| **DataDog** | APM + Infrastructure | $150 |
| **Vercel** | Next.js hosting (Pro plan) | $20 |
| **Misc** | DNS, backups, etc. | $50 |
| **Total** | | **$1,490/month** |

**Per Gym**: $1,490 / 50 = **$29.80/gym/month**

**Gross Margin**:
- Revenue: $199/gym/month (SaaS pricing)
- Cloud Cost: $30/gym/month
- **Margin**: 85%

### 12.3 Pricing Model

**Gym Subscription Tiers**:

| Tier | Price | Max Stations | Max Members | Features |
|------|-------|--------------|-------------|----------|
| **Starter** | $199/month | 1 | 100 | Basic analytics, standard support |
| **Professional** | $349/month | 3 | 300 | Advanced analytics, equipment tracking, priority support |
| **Enterprise** | $699/month | Unlimited | Unlimited | White-label, API access, dedicated support, custom integrations |

**Hardware Options**:
1. **Purchase**: $2,243 upfront (gym owns hardware)
2. **Finance**: $100/month for 24 months (0% APR)
3. **Lease**: Included in tier price + $150/month hardware fee

**Revenue Projections** (5-year):

| Year | Gyms | Avg Tier | MRR | ARR |
|------|------|----------|-----|-----|
| 1 | 50 | Starter | $9,950 | $119,400 |
| 2 | 150 | Mixed | $37,350 | $448,200 |
| 3 | 400 | Mixed | $105,600 | $1,267,200 |
| 4 | 800 | Mixed | $224,000 | $2,688,000 |
| 5 | 1,500 | Mixed | $448,500 | $5,382,000 |

---

## 13. Risk Mitigation

### 13.1 Technical Risks

**Risk**: MediaPipe accuracy insufficient for boxing analysis
**Mitigation**:
- Validate with boxing coaches during pilot
- Collect edge cases and improve prompts
- Phase 2: Train custom pose model

**Risk**: Edge devices fail in gym environment
**Mitigation**:
- Ruggedized enclosures
- Remote monitoring and diagnostics
- Spare devices for quick replacement
- 24/7 support SLA

**Risk**: Network connectivity issues
**Mitigation**:
- Offline mode: Store assessments locally, sync later
- 4G LTE backup (optional add-on)
- Clear error messages for gym staff

**Risk**: GPT-4 API costs too high
**Mitigation**:
- Cache common workout templates
- Use GPT-3.5 for simpler workouts
- Phase 2: Train custom workout generation model

### 13.2 Business Risks

**Risk**: Gyms don't see value, high churn
**Mitigation**:
- 30-day free trial
- Success metrics tracking (member retention)
- Regular check-ins with gym owners
- Feature requests and roadmap transparency

**Risk**: Slow sales cycle
**Mitigation**:
- Partner with gym chains for bulk deals
- Attend boxing/fitness trade shows
- Referral program (1 month free per referral)
- Case studies and testimonials

**Risk**: Competition from established fitness tech
**Mitigation**:
- Focus on boxing-specific expertise
- Build community (coaches, members)
- Continuous innovation
- Patent key technologies

---

## Appendices

### A. Glossary

- **Assessment Station**: Fixed camera setup in gym for technique analysis
- **Edge Device**: Nvidia Jetson computer that processes video locally
- **Pose Estimation**: AI detection of body keypoints (shoulders, hips, etc.)
- **Biomechanics**: Study of body movement and forces
- **Shadowboxing**: Boxing practice without a partner or bag

### B. References

- MediaPipe BlazePose: https://google.github.io/mediapipe/solutions/pose.html
- Nvidia Jetson Orin: https://www.nvidia.com/en-us/autonomous-machines/jetson-orin/
- FastAPI Documentation: https://fastapi.tiangolo.com/
- React Native: https://reactnative.dev/

### C. Contact Information

**Technical Questions**: tech@gideonboxing.ai
**Sales Inquiries**: sales@gideonboxing.ai
**Support**: support@gideonboxing.ai

---

**Document End**

This technical architecture document should be reviewed and updated quarterly as the product evolves. Major changes should be versioned and communicated to the engineering team.

**Next Steps**:
1. Review with engineering team
2. Validate hardware choices with pilot gym
3. Finalize technology stack decisions
4. Begin Month 1 development sprint
5. Set up infrastructure (AWS accounts, repositories)
