// Gestionnaire SSE (Server-Sent Events)
// Permet au serveur de pousser des mises a jour instantanees vers les navigateurs

const clients = new Set();

/**
 * Middleware Express — enregistre le client SSE et garde la connexion ouverte
 */
function sseHandler(req, res) {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.flushHeaders();

  // Envoyer un ping initial pour confirmer la connexion
  res.write('event: connected\ndata: ok\n\n');

  clients.add(res);
  console.log('[SSE] Client connecte. Total:', clients.size);

  // Supprimer le client quand il se deconnecte
  req.on('close', () => {
    clients.delete(res);
    console.log('[SSE] Client deconnecte. Total:', clients.size);
  });
}

/**
 * Envoyer un evenement a TOUS les clients connectes
 * @param {string} event  - Nom de l'evenement (ex: 'sermon_update')
 * @param {object} data   - Donnees JSON a envoyer
 */
function broadcast(event, data) {
  const payload = `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
  let count = 0;
  for (const client of clients) {
    try {
      client.write(payload);
      count++;
    } catch (e) {
      clients.delete(client);
    }
  }
  if (count > 0) console.log(`[SSE] Broadcast "${event}" -> ${count} client(s)`);
}

module.exports = { sseHandler, broadcast };
