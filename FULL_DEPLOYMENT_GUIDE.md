# 🚀 Full Deployment Guide: Render (Backend) + Vercel (Frontend)

This guide covers how to deploy your Spring Boot backend to **Render** and your Flutter frontend to **Vercel**.

---

## 🛠 Prerequisites

1.  **GitHub Account**: Ensure your code is pushed to a GitHub repository (I have already done this for you).
2.  **Render Account**: Sign up at [dashboard.render.com](https://dashboard.render.com/).
3.  **Vercel Account**: Sign up at [vercel.com](https://vercel.com/).
4.  **Vercel CLI**: Installed on your machine (`npm install -g vercel`).

---

## Part 1: Deploy Backend to Render (Java/Docker)

Since your backend is a Java Spring Boot application, we will use **Render** which supports Docker containers natively.

1.  **Log in to Render**.
2.  Click **New +** and select **Web Service**.
3.  Connect your GitHub repository (`recQ`).
4.  **Configure the Service**:
    *   **Name**: `recq-backend` (or similar).
    *   **Region**: Choose the one closest to you.
    *   **Runtime**: **Docker** (Render should auto-detect this because of the `Dockerfile` in the root).
    *   **Instance Type**: **Free**.
5.  Click **Create Web Service**.

⏳ **Wait for Deployment**: Render will build the Docker image. This takes about 3-5 minutes.
✅ **Copy URL**: Once finished, you will see a URL at the top left (e.g., `https://recq-backend.onrender.com`). **Copy this URL.**

---

## Part 2: Connect Frontend to Backend

Now we need to tell the Flutter app to talk to your new Render backend instead of `localhost`.

1.  Open the file `flutter_app/lib/config/api_config.dart` in your project.
2.  Find the line:
    ```dart
    static const String productionUrl = 'https://your-app-name.onrender.com';
    ```
3.  **Replace** the placeholder URL with your **actual Render URL** from Part 1.
    *   Example: `static const String productionUrl = 'https://recq-backend-xyz.onrender.com';`
4.  **Save** the file.

---

## Part 3: Deploy Frontend to Vercel (Flutter Web)

Vercel is great for static sites, but it doesn't have Flutter installed by default. The best way is to **build locally** and deploy the output.

1.  **Open Terminal** and navigate to the frontend folder:
    ```bash
    cd flutter_app
    ```

2.  **Build the Web App**:
    This creates the static HTML/JS/CSS files in `build/web`.
    ```bash
    flutter build web --release --no-tree-shake-icons
    ```

3.  **Prepare Routing** (One-time setup):
    Ensure `vercel.json` is in the build folder (I have already created it, just copy it over).
    ```bash
    cp vercel.json build/web/
    ```

4.  **Deploy using Vercel CLI**:
    ```bash
    cd build/web
    vercel deploy --prod
    ```
    *   **Log in** if prompted.
    *   **Scope**: Select your personal account.
    *   **Link to Project**: `No` (or `Yes` if you want to create a new project in Vercel dashboard).
    *   **Project Name**: `recq-frontend`.
    *   **Directory**: Keep default (`.`).
    *   **Modify settings?**: `No`.

✅ **Done!** Vercel will give you a Production URL (e.g., `https://recq-frontend.vercel.app`).

---

## 🎉 Final Verification

1.  Open your **Vercel URL** in a browser (e.g., Chrome/Safari).
2.  Try to **Login** (admin/admin).
3.  If it logs in successfully, your Frontend is correctly talking to your Backend on Render!

### ⚠️ Troubleshooting
*   **Login Failed / Network Error**:
    *   Check if the Backend on Render is running (open the Render URL in browser; it should show a whitelabel error page or 404, which is normal for Spring Boot root).
    *   Ensure you updated `api_config.dart` with the *exact* Render URL (no trailing slash).
    *   Ensure you ran `flutter build web` *after* updating the config.
