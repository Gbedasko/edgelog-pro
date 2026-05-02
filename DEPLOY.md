# EdgeLog Pro — Deployment Guide

## STEP 1: Run the Database Schema in Supabase

1. Go to: https://supabase.com/dashboard/project/tjefloldgvrvqpdilaxv/sql/new
2. Copy the entire contents of `supabase-schema.sql`
3. Paste it into the SQL editor
4. Click **Run**
5. You should see "Success. No rows returned"

## STEP 2: Verify Storage Bucket

1. Go to: https://supabase.com/dashboard/project/tjefloldgvrvqpdilaxv/storage/buckets
2. Confirm bucket named `screenshots` exists and is set to **Public**
3. If it does not exist, click **New bucket**, name it `screenshots`, check **Public bucket**, click Save

## STEP 3: Install and Run Locally (Test First)

You need Node.js installed. Download from: https://nodejs.org (LTS version)

Open terminal / command prompt in the project folder, then run:
```
npm install
npm run dev
```

Open browser at: http://localhost:3000

Test the full flow:
- Create an account
- Create a strategy
- Log a trade with a screenshot
- Check discipline score

## STEP 4: Deploy to Vercel

1. Go to: https://vercel.com
2. Sign up / log in with your GitHub account
3. Upload the project folder to GitHub (or use Vercel CLI)
4. Click **Add New Project** → import the repo
5. In **Environment Variables**, add all variables from `.env.local`:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `DATABASE_URL`
   - `OPENAI_API_KEY`
   - `NEXT_PUBLIC_APP_URL` → set this to your Vercel URL after first deploy
6. Click **Deploy**

## STEP 5: Update Supabase Auth Redirect

After Vercel gives you a URL (e.g. `https://edgelog-pro.vercel.app`):

1. Go to: https://supabase.com/dashboard/project/tjefloldgvrvqpdilaxv/auth/url-configuration
2. Set **Site URL** to your Vercel URL
3. Add your Vercel URL to **Redirect URLs** (add `https://yourapp.vercel.app/**`)
4. Save

## DONE — Your app is live.

---

## Credentials (keep private)

- Supabase URL: https://tjefloldgvrvqpdilaxv.supabase.co
- Supabase Dashboard: https://supabase.com/dashboard/project/tjefloldgvrvqpdilaxv
