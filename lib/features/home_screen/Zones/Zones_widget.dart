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
  bool _autoSelected = false;

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
        } else if (state is ZoneLoaded &&
            state.zones.isNotEmpty &&
            widget.selectedZoneId == null &&
            !_autoSelected) {
          _autoSelected = true;
          final firstId = (state.zones.first.zoneId ?? '0').toString();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onZoneSelected(firstId);
          });
        }
      },
      builder: (context, state) {
        if (state is ZoneLoaded) {
          if (state.zones.isEmpty) {
            return SizedBox(
              height: size.height * 0.03,
              child: const Center(
                child: Text(
                  'No zones found.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(state.zones.length, (index) {
                      final zone = state.zones[index];
                      final zoneId = (zone.zoneId ?? index).toString();
                      final isSelected = zoneId == widget.selectedZoneId;

                      return Padding(
                        padding: EdgeInsets.only(right: size.width * 0.05),
                        child: GestureDetector(
                          onTap: () => widget.onZoneSelected(zoneId),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                zone.zoneName ?? 'Unnamed',
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
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
          );
        }

        // ZoneError or any unexpected state — parent already handled
        // the initial loading spinner, so just show a light fallback.
        return SizedBox(
          height: size.height * 0.03,
          child: const Center(
            child: Text(
              'Unable to load zones.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        );
      },
    );
  }
}