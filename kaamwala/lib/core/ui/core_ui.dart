/// KaamWala UI 2.0 component library (overhaul M2).
///
/// Widgets here are the ONLY sanctioned way to build the recurring motifs:
/// icon wells, buttons, empty states, skeletons, stat cards. Screens must not
/// hand-roll BoxDecoration lookalikes - extend this library instead.
library;

import 'package:kaamwala/core/theme/app_theme.dart';

export 'kw_button.dart';
export 'kw_empty_state.dart';
export 'kw_icon_well.dart';
export 'kw_skeleton.dart';
export 'kw_stat_card.dart';

/// Re-exported so screens keep a single core-ui import.
typedef KwRadiusAlias = KwRadius;
