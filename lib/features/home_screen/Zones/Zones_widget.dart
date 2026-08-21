// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import '../../../constants/color_constants.dart';
// import 'Zones_bloc/zone_state.dart';
// import 'Zones_bloc/zones_bloc.dart';
//
// class ZoneTabs extends StatefulWidget {
//   final String? selectedZoneId;
//   final ValueChanged<String> onZoneSelected;
//
//   const ZoneTabs({
//     Key? key,
//     required this.onZoneSelected,
//     this.selectedZoneId,
//   }) : super(key: key);
//
//   @override
//   State<ZoneTabs> createState() => _ZoneTabsState();
// }
//
// class _ZoneTabsState extends State<ZoneTabs> {
//   bool _autoSelected = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return BlocConsumer<ZoneBloc, ZoneState>(
//       listener: (context, state) {
//         if (state is ZoneError) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(state.message),
//               backgroundColor: ColorConstants.errorColor,
//             ),
//           );
//         } else if (state is ZoneLoaded &&
//             state.zones.isNotEmpty &&
//             widget.selectedZoneId == null &&
//             !_autoSelected) {
//           _autoSelected = true;
//           final firstId = (state.zones.first.zoneId ?? '0').toString();
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             widget.onZoneSelected(firstId);
//           });
//         }
//       },
//       builder: (context, state) {
//         if (state is ZoneLoaded) {
//           if (state.zones.isEmpty) {
//             return SizedBox(
//               height: size.height * 0.03,
//               child: const Center(
//                 child: Text(
//                   'No zones found.',
//                   style: TextStyle(color: Colors.black54),
//                 ),
//               ),
//             );
//           }
//
//           // ─── UI only: wrap existing tabs in rounded pill (matches Figma) ───
//           return Container(
//             height: 44,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey.shade300, width: 1),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: List.generate(state.zones.length, (index) {
//                         final zone = state.zones[index];
//                         final zoneId = (zone.zoneId ?? index).toString();
//                         final isSelected = zoneId == widget.selectedZoneId;
//
//                         return Padding(
//                           padding: EdgeInsets.only(right: size.width * 0.05),
//                           child: GestureDetector(
//                             onTap: () => widget.onZoneSelected(zoneId),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   zone.zoneName ?? 'Unnamed',
//                                   style: TextStyle(
//                                     fontSize: size.width * 0.035,
//                                     fontWeight: isSelected
//                                         ? FontWeight.w700
//                                         : FontWeight.w500,
//                                     color: isSelected
//                                         ? ColorConstants.primaryColor
//                                         : Colors.black54,
//                                   ),
//                                 ),
//                                 SizedBox(height: size.height * 0.006),
//                                 Container(
//                                   height: 2,
//                                   width: size.width * 0.09,
//                                   color: isSelected
//                                       ? ColorConstants.primaryColor
//                                       : Colors.transparent,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         // ZoneError or any unexpected state — parent already handled
//         // the initial loading spinner, so just show a light fallback.
//         return SizedBox(
//           height: size.height * 0.03,
//           child: const Center(
//             child: Text(
//               'Unable to load zones.',
//               style: TextStyle(color: Colors.black54),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/color_constants.dart';
import 'Zones_bloc/zone_state.dart';
import 'Zones_bloc/zones_bloc.dart';

class ZoneTabs extends StatefulWidget {
  final String? selectedZoneId;
  final ValueChanged<String> onZoneSelected;

  const ZoneTabs({
    Key? key,
    required this.onZoneSelected,
    this.selectedZoneId,
  }) : super(key: key);

  @override
  State<ZoneTabs> createState() => _ZoneTabsState();
}

class _ZoneTabsState extends State<ZoneTabs> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _tabKeys = {};
  List<dynamic> _lastZones = [];
  GlobalKey _keyFor(String zoneId) =>
      _tabKeys.putIfAbsent(zoneId, () => GlobalKey());

  @override
  void didUpdateWidget(covariant ZoneTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedZoneId != null &&
        widget.selectedZoneId != oldWidget.selectedZoneId) {
      _scrollToSelected(widget.selectedZoneId!);
    }
  }

  void _scrollToSelected(String zoneId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _tabKeys[zoneId]?.currentContext;
      if (ctx != null && mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   final size = MediaQuery.of(context).size;
  //
  //   return BlocConsumer<ZoneBloc, ZoneState>(
  //     listener: (context, state) {
  //       if (state is ZoneError) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(state.message),
  //             backgroundColor: ColorConstants.errorColor,
  //           ),
  //         );
  //       }
  //     },
  //     builder: (context, state) {
  //       if (state is ZoneLoaded) {
  //         if (state.zones.isEmpty) {
  //           return SizedBox(
  //             height: size.height * 0.03,
  //             child: const Center(
  //               child: Text(
  //                 'No zones found.',
  //                 style: TextStyle(color: Colors.black54),
  //               ),
  //             ),
  //           );
  //         }
  //
  //         // ─── Auto-select the default zone whenever nothing is selected. ───
  //         // Runs on every build (not just on new bloc emissions), so this
  //         // fires correctly when returning to this screen with an already
  //         // ZoneLoaded bloc, and after refresh/sync resets selection to null.
  //         if (widget.selectedZoneId == null) {
  //           final firstId = (state.zones.first.zoneId ?? '0').toString();
  //           WidgetsBinding.instance.addPostFrameCallback((_) {
  //             if (mounted && widget.selectedZoneId == null) {
  //               widget.onZoneSelected(firstId);
  //             }
  //           });
  //         } else {
  //           // Keep the currently selected tab visible (e.g. after data reload).
  //           _scrollToSelected(widget.selectedZoneId!);
  //         }
  //
  //         return Container(
  //           height: 44,
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(12),
  //             // ─── Design fix: drop shadow instead of stroke/border ───
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.08),
  //                 blurRadius: 10,
  //                 spreadRadius: 0,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           padding: const EdgeInsets.symmetric(horizontal: 12),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: SingleChildScrollView(
  //                   controller: _scrollController,
  //                   scrollDirection: Axis.horizontal,
  //                   child: Row(
  //                     children: List.generate(state.zones.length, (index) {
  //                       final zone = state.zones[index];
  //                       final zoneId = (zone.zoneId ?? index).toString();
  //                       final isSelected = zoneId == widget.selectedZoneId;
  //
  //                       return Padding(
  //                         key: _keyFor(zoneId),
  //                         padding: EdgeInsets.only(right: size.width * 0.05),
  //                         child: GestureDetector(
  //                           onTap: () {
  //                             widget.onZoneSelected(zoneId);
  //                             _scrollToSelected(zoneId);
  //                           },
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: [
  //                               Text(
  //                                 zone.zoneName ?? 'Unnamed',
  //                                 style: TextStyle(
  //                                   fontSize: size.width * 0.035,
  //                                   fontWeight: isSelected
  //                                       ? FontWeight.w700
  //                                       : FontWeight.w500,
  //                                   color: isSelected
  //                                       ? ColorConstants.primaryColor
  //                                       : Colors.black54,
  //                                 ),
  //                               ),
  //                               SizedBox(height: size.height * 0.006),
  //                               Container(
  //                                 height: 2,
  //                                 width: size.width * 0.09,
  //                                 color: isSelected
  //                                     ? ColorConstants.primaryColor
  //                                     : Colors.transparent,
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     }),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       }
  //
  //       return SizedBox(
  //         height: size.height * 0.03,
  //         child: const Center(
  //           child: Text(
  //             'Unable to load zones.',
  //             style: TextStyle(color: Colors.black54),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocConsumer<ZoneBloc, ZoneState>(
      listener: (context, state) {
        if (state is ZoneError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ColorConstants.errorColor,
            ),
          );
        }
        if (state is ZoneLoaded) {
          _lastZones = state.zones; // keep latest good data
        }
      },
      builder: (context, state) {
        // Prefer current loaded data, otherwise fall back to last known zones
        final zones = state is ZoneLoaded ? state.zones : _lastZones;

        if (zones.isEmpty) {
          // Real error → show message
          if (state is ZoneError) {
            return SizedBox(
              height: size.height * 0.03,
              child: const Center(
                child: Text(
                  'Unable to load zones.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          return SizedBox(
            height: size.height * 0.03,
            child: const Center(
              child: CupertinoActivityIndicator(radius: 10),
            ),
          );
        }
        if (widget.selectedZoneId == null) {
          final firstId = (zones.first.zoneId ?? '0').toString();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.selectedZoneId == null) {
              widget.onZoneSelected(firstId);
            }
          });
        } else {
          _scrollToSelected(widget.selectedZoneId!);
        }

        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(zones.length, (index) {
                      final zone = zones[index];
                      final zoneId = (zone.zoneId ?? index).toString();
                      final isSelected = zoneId == widget.selectedZoneId;

                      return Padding(
                        key: _keyFor(zoneId),
                        padding: EdgeInsets.only(right: size.width * 0.05),
                        child: GestureDetector(
                          onTap: () {
                            widget.onZoneSelected(zoneId);
                            _scrollToSelected(zoneId);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                zone.zoneName ?? 'Unnamed',
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? ColorConstants.primaryColor
                                      : Colors.black54,
                                ),
                              ),
                              SizedBox(height: size.height * 0.006),
                              Container(
                                height: 2,
                                width: size.width * 0.09,
                                color: isSelected
                                    ? ColorConstants.primaryColor
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}