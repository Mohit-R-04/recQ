# Deployment Guide

## 1. Backend (Render) - 🚀 DO THIS FIRST
1.  Push code to GitHub.
2.  Create Web Service on [Render](https://dashboard.render.com/).
3.  Connect your repo `recQ`.
4.  Select **Docker** Runtime (auto-detected).
5.  Deploy and **COPY THE URL** (e.g., `https://recq-backend.onrender.com`).

---

## 2. Connect Frontend
1.  Open `flutter_app/lib/config/api_config.dart`.
2.  Paste your Render URL into `productionUrl`.
3.  Save the file.

---

## 3. Frontend (Vercel) - ⚡️ DO THIS SECOND

### Option A: Using Vercel CLI (Recommended)
Since Vercel doesn't have Flutter installed by default, it's easiest to build on your machine and deploy the output.

1.  **Install Vercel CLI**:
    ```bash
    npm install -g vercel
    ```

2.  **Build the Web App**:
    ```bash
    cd flutter_app
    flutter build web --release --no-tree-shake-icons
    ```

3.  **Prepare for Routing**:
    Copy the configuration file to the build folder:
    ```bash
    cp vercel.json build/web/
    ```

4.  **Deploy**:
    ```bash
    cd build/web
    vercel deploy --prod
    ```
    *   Follow the prompts (say "Y" to everything).
    *   It will give you a production URL (e.g., `https://recq-frontend.vercel.app`).

### Option B: Git Integration (Advanced)
If you want Vercel to build it automatically when you push to GitHub, you need to configure a custom Build Command in Vercel settings to install Flutter first, which is complex and prone to breaking. **Option A is strictly recommended.**
