/// How a scene's layer moves, chosen by the layer's name. Motions are big
/// enough to notice at a glance, yet smooth and looping.
enum IllustrationMotion {
  /// Backgrounds, floors, furniture, devices.
  still,

  /// People: a slow rise and fall.
  bob,

  /// Plants: lean left and right from the pot.
  sway,

  /// Speech bubbles, pins, notifications, photos: drift up and down.
  float,

  /// Hanging things (a lamp): swing from the top.
  swing,

  /// A soft ring that grows and fades back.
  pulse,

  /// Enters once: grows in from nothing with a little overshoot.
  pop,

  /// Enters once: spreads out from the middle.
  burst,

  /// Enters once: drawn in from left to right (a check mark).
  draw,
}

/// Layer name → motion. The names are Storyset's layer names, lower-cased,
/// plus the success badge's own (`branding/illustrations/success_check.svg`).
IllustrationMotion motionFor(String layer) {
  for (final (prefix, motion) in _motions) {
    if (layer.startsWith(prefix)) return motion;
  }
  return IllustrationMotion.still;
}

const _motions = [
  ('character', IllustrationMotion.bob),
  ('plant', IllustrationMotion.sway),
  ('speech-bubble', IllustrationMotion.float),
  ('notifications', IllustrationMotion.float),
  ('message', IllustrationMotion.float),
  ('locators', IllustrationMotion.float),
  ('photo', IllustrationMotion.float),
  ('document', IllustrationMotion.float),
  ('rocket', IllustrationMotion.float),
  ('elements', IllustrationMotion.float),
  ('sun', IllustrationMotion.float),
  ('lamp', IllustrationMotion.swing),
  ('halo', IllustrationMotion.pulse),
  ('badge', IllustrationMotion.pop),
  ('burst', IllustrationMotion.burst),
  ('check', IllustrationMotion.draw),
];
