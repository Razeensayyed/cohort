class PortfolioData {
  static const String name = 'Bushra Kazi';
  static const String title = 'AI & ML Engineer';
  static const String subtitle = 'BE CSE (AI & ML) Student | CGPA 9.61';
  static const String location = 'Mumbai, Maharashtra';
  static const String email = 'bushrakazi68@gmail.com';
  static const String phone = '+91 8655422852';
  static const String linkedin = 'https://linkedin.com/in/bushra-kazi-b5067237a';
  static const String github = 'https://github.com/bushrakazi68-arch';

  static const String summary =
      'AI & ML engineering student with a Semester 4 CGPA of 9.61 and Winner of the AICW 2.0 Project Expo (AI Careers for Women – Edunet Foundation, Microsoft & SAP), ranked first in the program assessment. Builds AI systems end to end — from computer-vision models in PyTorch/YOLO to multi-agent LLM platforms with LangGraph, RAG, and graph databases. Seeking an AI/ML or software engineering internship.';

  static const List<Map<String, dynamic>> skills = [
    {
      'category': 'Languages',
      'icon': '💻',
      'items': ['Python', 'Java', 'JavaScript', 'TypeScript'],
    },
    {
      'category': 'AI / ML',
      'icon': '🤖',
      'items': [
        'PyTorch',
        'PyTorch Geometric',
        'YOLO (Ultralytics)',
        'LangGraph',
        'RAG (ChromaDB)',
        'Groq API',
        'NumPy',
        'Computer Vision',
      ],
    },
    {
      'category': 'Web & Backend',
      'icon': '🌐',
      'items': [
        'FastAPI',
        'Node.js / Express',
        'React',
        'Vite',
        'Tailwind CSS',
        'HTML & CSS',
        'WebSocket',
        'Streamlit',
      ],
    },
    {
      'category': 'Databases & Tools',
      'icon': '🛠️',
      'items': [
        'Neo4j',
        'SQLite',
        'SQLAlchemy',
        'Git & GitHub',
        'VS Code',
        'Jupyter Notebook',
        'DSA',
        'OOP',
      ],
    },
  ];

  static const List<Map<String, String>> projects = [
    {
      'title': 'TruthLens',
      'subtitle': 'Multi-Agent Misinformation Detection & Containment Platform',
      'description':
          'End-to-end pipeline that ingests live content from NewsAPI, YouTube Data API and RSS fact-check feeds, deduplicates it, and orchestrates four specialised LangGraph agents — claim detector, origin tracer, spread predictor, and RAG counter-narrative drafter — with a human-in-the-loop review gate for high-severity claims. Built a Neo4j provenance graph tracing each claim to its earliest outlet and an explainable spread-risk model estimating R0 and 6-hour reach.',
      'tech': 'Python · FastAPI · LangGraph · Neo4j · Groq LLM · ChromaDB (RAG) · PyTorch Geometric · React · TypeScript · Node/Express',
      'emoji': '🔍',
      'color': '0xFF6C63FF',
    },
    {
      'title': 'AegisSentra',
      'subtitle': 'Runtime Integrity Monitor for Multi-Agent AI Systems',
      'description':
          'Solo full-stack monitor (backend, frontend and detection logic) that watches a 3-agent AI pipeline (RECON → SAGE → ECHO) and streams live threat alerts to a React dashboard over WebSockets. Designed a trust-scoring system (0–100) with YAML policy rules that automatically quarantines compromised agents, detecting 5 attack types including Prompt Injection and Identity Spoofing.',
      'tech': 'Python · FastAPI · React · Vite · SQLite · SQLAlchemy · Groq API · Framer Motion · Tailwind CSS · WebSocket · asyncio',
      'emoji': '🛡️',
      'color': '0xFF00D4AA',
    },
    {
      'title': 'Pothole Detection & Severity Grader',
      'subtitle': 'Computer Vision Road-Damage Detection System',
      'description':
          'Road-damage app that detects potholes in photos and videos, grades each Low/Medium/High by size, with live preview, batch processing, GPS map view and a history database. Trained and compared four YOLO models (v8s, v9s, v11s, v12s); all four achieved mAP@50 of ~0.62–0.64 on a held-out test set of 124 images. Added confidence threshold tuning and PDF report export.',
      'tech': 'YOLO (Ultralytics) · Python · Streamlit · PyTorch',
      'emoji': '🚧',
      'color': '0xFFFF6B6B',
    },
  ];

  static const List<Map<String, String>> achievements = [
    {
      'emoji': '🏆',
      'title': 'Winner – AICW 2.0 Project Expo',
      'description':
          'AI Careers for Women (Empowering Women for an AI-Powered World), M.H. Saboo Siddik College of Engineering with Edunet Foundation, Microsoft & SAP (Jul–Sep 2026). Awarded for innovation and technical excellence in the capstone project.',
    },
    {
      'emoji': '🥇',
      'title': 'First Rank – Program Assessment',
      'description':
          'Ranked first in the AI Careers for Women program assessment, Edunet Foundation, Microsoft & SAP, 30 July – 24 September 2026.',
    },
    {
      'emoji': '📄',
      'title': 'Research Paper Published',
      'description':
          '"Kitchen Based Affordable Meal Aggregator Platform for PG and Hostel Residents" presented at SmartSSD 2026 International Conference.',
    },
    {
      'emoji': '🎯',
      'title': 'Project Exhibition & Idea Generation',
      'description':
          'Participated in Project Exhibition 2026 (R&D Cell) and Innovative Idea Generation Competition 2026 (E-Cell), MHSSCE.',
    },
  ];

  static const Map<String, String> education = {
    'degree': 'Bachelor of Engineering (B.E.)',
    'branch': 'Computer Science & Engineering (AI & ML)',
    'college': 'M.H. Saboo Siddik College of Engineering, Mumbai',
    'graduation': 'Expected 2028',
    'sem4': '9.61',
    'sem3': '9.27',
    'firstYear': '8.57',
  };
}
