# Recommandations Anti-Fraude pour Entourage

Suite à l'attaque récente ayant généré des milliers de faux comptes, voici une liste de mesures complémentaires à Rack::Attack pour renforcer la sécurité de l'application.

## 1. Protection du Front-end : CAPTCHA
L'ajout d'un CAPTCHA (comme **reCAPTCHA v3** ou **hCaptcha**) sur les formulaires de création de compte est l'une des méthodes les plus efficaces pour bloquer les bots tout en restant transparent pour les utilisateurs légitimes.

- **Action** : Intégrer un CAPTCHA sur la page d'inscription de l'application mobile et du backoffice.

## 2. Validation du Numéro de Téléphone
L'attaque a utilisé des milliers de SMS. Pour limiter cela :
- **Détection de numéros VOIP/Landline** : Utiliser des services comme l'API de Twilio ou Vonage pour vérifier si un numéro est un mobile réel ou un numéro virtuel (souvent utilisé par les bots).
- **Limitation par préfixe/pays** : Si l'application cible principalement la France, limiter ou surveiller étroitement les inscriptions avec des numéros provenant de pays inhabituels.

## 3. Filtrage des Emails
- **Blocklist de domaines jetables** : Interdire les inscriptions utilisant des services d'emails temporaires (ex: mailinator, 10minutemail).
- **Vérification de domaine** : S'assurer que le domaine de l'email possède des enregistrements MX valides.

## 4. Analyse du Comportement et Réputation d'IP
- **Détection de VPN/Proxy/TOR** : Bloquer ou soumettre à un CAPTCHA plus strict les requêtes provenant d'IP connues comme étant des nœuds de sortie VPN ou TOR.
- **Services tiers** : Utiliser des services comme **Cloudflare** ou **Datadome** qui gèrent automatiquement la réputation des IP et le blocage des bots au niveau DNS/Edge.

## 5. Limitation du Débit (Rate Limiting) applicatif
En plus de Rack::Attack, implémenter des compteurs en base de données pour :
- Limiter le nombre d'envois de SMS par numéro de téléphone sur 24h (ex: max 3 tentatives).
- Limiter le nombre de comptes créés par IP sur une période glissante plus longue (ex: max 10 comptes par jour).

## 6. Processus d'Inscription en deux étapes (Double Opt-in)
Actuellement, le SMS est envoyé immédiatement.
- **Alternative** : Demander d'abord l'email, envoyer un lien de confirmation, et seulement après validation de l'email, demander le numéro de téléphone pour l'envoi du SMS. Cela ajoute une barrière supplémentaire pour les scripts automatisés.
