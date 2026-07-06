# Put your Ghost agent on iMessage — quick start

Three steps, about 5 minutes. You don't need to understand any of the technical bits —
the script handles them.

---

## 1️⃣ Get your 2 keys (on the web — no terminal)
1. Go to **https://app.photon.codes** and sign up.
2. Click **Create project** → choose **iMessage**.
3. **Add your phone number** when asked (so you're allowed to text it).
4. Copy the two values it shows — **PROJECT_ID** and **PROJECT_SECRET**. Keep them nearby.
   (Also note the **phone number** it gives you — that's what you'll text.)

## 2️⃣ Open a terminal and run the file
- **Mac:** open the **Terminal** app (Spotlight → type "Terminal").
- **Windows:** open **Ubuntu** (Start menu → type "Ubuntu").
  Not there? Open **PowerShell**, run `wsl --install`, restart, then open Ubuntu.

Then paste this line and press **Enter** (it assumes `deploy.sh` is in your Downloads):

- **Mac:**
  ```
  bash ~/Downloads/deploy.sh
  ```
- **Windows (Ubuntu):** (replace `YOUR-NAME` with your Windows username)
  ```
  bash /mnt/c/Users/YOUR-NAME/Downloads/deploy.sh
  ```

## 3️⃣ Answer the prompts
- If it asks you to **sign in**, a link appears → open it → click **Approve**.
- It **finds your agent automatically**.
- **Paste your PROJECT_ID and PROJECT_SECRET** when asked.
- Wait ~30 seconds until it says **✓ Done!**

---

## ✅ Test it
Text your **Photon phone number** (from step 1) using the phone you added.
Your agent replies in a few seconds. 🎉

## 🙅 Don't want to touch a terminal at all?
You can skip steps 2 and 3 entirely. Just do the **web part**:
1. Create your Photon project (step 1 above) and copy your **PROJECT_ID** and **PROJECT_SECRET**.
2. Send those two keys to whoever gave you this file, along with a note that your agent is a **Hermes** agent.
3. They run the setup for you, and you just **text the line**.

(The only catch: the person running it needs access to your agent's VM — easiest if you're on the same team/account.)

## 🆘 If something's off
- **"bash: command not found" / nothing happens on Windows** → you're not in Ubuntu. Open the **Ubuntu** app, not PowerShell.
- **The reply says "out of credits"** → your agent needs model balance topped up.
- **No reply at all** → make sure you texted from the exact phone number you added in step 1.
- **Still stuck?** Send whoever gave you this file a screenshot of your terminal.
