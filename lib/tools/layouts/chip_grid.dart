import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:otraku/services/config.dart';
import 'package:otraku/enums/enum_helper.dart';
import 'package:otraku/tools/fields/chip_field.dart';
import 'package:otraku/tools/fields/three_state_field.dart';

class ChipGrid<T> extends StatefulWidget {
  final String title;
  final String placeholder;
  final List<String> options;
  final List<T> values;
  final List<T> inclusive;
  final List<T> exclusive;

  ChipGrid({
    @required this.title,
    @required this.placeholder,
    @required this.options,
    @required this.values,
    @required this.inclusive,
    @required this.exclusive,
  });

  @override
  _ChipGridState createState() => _ChipGridState();
}

class _ChipGridState extends State<ChipGrid> {
  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.subtitle1),
              IconButton(
                icon: Icon(FluentSystemIcons.ic_fluent_settings_dev_filled),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => _OptionSheet(
                    options: widget.options,
                    values: widget.values,
                    inclusive: [...widget.inclusive],
                    exclusive: [...widget.exclusive],
                    onDone: (inclusive, exclusive) {
                      setState(() {
                        widget.inclusive.clear();
                        widget.exclusive.clear();
                        for (final i in inclusive) widget.inclusive.add(i);
                        for (final e in exclusive) widget.exclusive.add(e);
                      });
                    },
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
          widget.inclusive.length + widget.exclusive.length > 0
              ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(
                        widget.inclusive.length,
                        (index) {
                          String value = widget.inclusive[index];

                          return ChipField(
                            key: UniqueKey(),
                            title: clarifyEnum(value),
                            initiallyPositive: true,
                            onChanged: (changed) {
                              if (changed) {
                                widget.exclusive.remove(value);
                                widget.inclusive.add(value);
                              } else {
                                widget.inclusive.remove(value);
                                widget.exclusive.add(value);
                              }
                            },
                            onRemoved: () =>
                                setState(() => widget.inclusive.remove(value)),
                          );
                        },
                      ) +
                      List.generate(
                        widget.exclusive.length,
                        (index) {
                          String value = widget.exclusive[index];

                          return ChipField(
                            key: UniqueKey(),
                            title: clarifyEnum(value),
                            initiallyPositive: false,
                            onChanged: (changed) {
                              if (changed) {
                                widget.exclusive.remove(value);
                                widget.inclusive.add(value);
                              } else {
                                widget.inclusive.remove(value);
                                widget.exclusive.add(value);
                              }
                            },
                            onRemoved: () =>
                                setState(() => widget.exclusive.remove(value)),
                          );
                        },
                      ),
                )
              : SizedBox(
                  height: Config.MATERIAL_TAP_TARGET_SIZE,
                  child: Center(
                    child: Text(
                      'No selected ${widget.placeholder}',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
        ],
      );
}

class _OptionSheet<T> extends StatelessWidget {
  final List<String> options;
  final List<T> values;
  final List<T> inclusive;
  final List<T> exclusive;
  final Function(List<T>, List<T>) onDone;

  _OptionSheet({
    @required this.options,
    @required this.values,
    @required this.inclusive,
    @required this.exclusive,
    @required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 10,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: Config.BORDER_RADIUS,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              physics: Config.PHYSICS,
              itemBuilder: (_, index) => ThreeStateField(
                title: options[index],
                initialState: inclusive.contains(values[index])
                    ? 1
                    : exclusive.contains(values[index])
                        ? 2
                        : 0,
                onChanged: (state) {
                  if (state == 0) {
                    exclusive.remove(values[index]);
                  } else if (state == 1) {
                    inclusive.add(values[index]);
                  } else {
                    inclusive.remove(values[index]);
                    exclusive.add(values[index]);
                  }
                },
              ),
              itemCount: options.length,
            ),
          ),
          FlatButton.icon(
            onPressed: () {
              onDone(inclusive, exclusive);
              Navigator.pop(context);
            },
            icon: Icon(
              FluentSystemIcons.ic_fluent_checkmark_filled,
              color: Theme.of(context).accentColor,
            ),
            label: Text('Done', style: Theme.of(context).textTheme.bodyText2),
          ),
        ],
      ),
    );
  }
}
