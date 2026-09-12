export function validateSpeech(body) {
  if (!body || typeof body.text !== 'string' || !['en', 'ta'].includes(body.language)) throw new Error('Invalid request');
  const text = body.text.trim();
  if (text.length < 1 || text.length > 1800) throw new Error('Advice must be 1–1800 characters');
  return {text, language:body.language};
}
export function withinBudget(user, global, length) {
  return user + length <= 10000 && global + length <= 100000;
}
