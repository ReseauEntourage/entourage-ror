# Jules Slack Integration Setup

To connect Jules to Slack, follow these steps:

## 1. Create a Slack App
1. Go to [Slack API: Applications](https://api.slack.com/apps) and click **Create New App**.
2. Choose **From scratch**, name your app "Jules", and select your workspace.

## 2. Configure Scopes
1. Go to **OAuth & Permissions**.
2. Under **Scopes > Bot Token Scopes**, add the following:
   - `app_mentions:read`: To allow Jules to see when it is mentioned.
   - `chat:write`: To allow Jules to send messages back to the channel.

## 3. Enable Event Subscriptions
1. Go to **Event Subscriptions** and toggle **Enable Events**.
2. Set the **Request URL** to `https://your-domain.com/api/v1/slack/events`.
3. Under **Subscribe to bot events**, add:
   - `app_mention`
4. Save Changes.

## 4. Install App to Workspace
1. Go to **Install App** and click **Install to Workspace**.
2. Copy the **Bot User OAuth Token** (starts with `xoxb-`).

## 5. Configure Rails Environment
Add the following variables to your `.env` or secrets:
- `SLACK_BOT_TOKEN`: The Bot User OAuth Token.
- `SLACK_SIGNING_SECRET`: Found in **Basic Information > App Credentials**.
- `OPENAI_API_KEY`: Required for the AI analysis (Jules' brain).

## 6. Invite Jules to Channels
In Slack, invite the Jules bot to any channel where you want it to be active:
`/invite @Jules`
