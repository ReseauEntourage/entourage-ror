import { createConsumer } from "actioncable"

// Le token est généré côté serveur (ApplicationController#cable_auth_token)
// et passé via meta tag. Sans token, pas de connexion WebSocket (ex: page login).
const token = document.querySelector("meta[name='cable-token']")?.content

const consumer = token
  ? createConsumer(`/cable?token=${encodeURIComponent(token)}`)
  : null

export default consumer
