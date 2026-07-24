/// Mapeo visual centralizado del catálogo de deportes.
///
/// Los emojis son una decisión de presentación y no se persisten en
/// Supabase. El fallback evita reutilizar por accidente el icono de fútbol.
String sportEmoji(String sportId) => switch (sportId.toLowerCase()) {
  'futbol' || 'fútbol' || 'football' || 'soccer' => '\u{26BD}',
  'basquetbol' || 'básquetbol' || 'basketball' => '\u{1F3C0}',
  'tenis' || 'tennis' || 'padel' || 'pádel' => '\u{1F3BE}',
  'voleibol' || 'vóleibol' || 'volleyball' => '\u{1F3D0}',
  'natacion' || 'natación' || 'swimming' => '\u{1F3CA}',
  'running' || 'trote' || 'atletismo' => '\u{1F3C3}',
  'all' => '\u{1F3C5}',
  _ => '\u{1F3C5}',
};
