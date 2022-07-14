import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/constants/consts.dart';
import 'package:otraku/constants/media_sort.dart';
import 'package:otraku/media/media_grid.dart';
import 'package:otraku/staff/staff_providers.dart';
import 'package:otraku/studio/studio_models.dart';
import 'package:otraku/studio/studio_providers.dart';
import 'package:otraku/utils/convert.dart';
import 'package:otraku/utils/pagination_controller.dart';
import 'package:otraku/widgets/fields/drop_down_field.dart';
import 'package:otraku/widgets/grids/sliver_grid_delegates.dart';
import 'package:otraku/widgets/layouts/floating_bar.dart';
import 'package:otraku/widgets/layouts/page_layout.dart';
import 'package:otraku/widgets/loaders.dart/loaders.dart';
import 'package:otraku/widgets/overlays/dialogs.dart';
import 'package:otraku/widgets/overlays/sheets.dart';
import 'package:otraku/widgets/overlays/toast.dart';

class StudioView extends ConsumerStatefulWidget {
  StudioView(this.id, this.name);

  final int id;
  final String? name;

  @override
  ConsumerState<StudioView> createState() => _StudioViewState();
}

class _StudioViewState extends ConsumerState<StudioView> {
  late final PaginationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PaginationController(loadMore: () {
      ref.read(studioProvider(widget.id).notifier).fetchPage();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refreshControl = SliverRefreshControl(
      onRefresh: () {
        ref.invalidate(staffProvider(widget.id));
        return Future.value();
      },
    );

    final studio = ref.watch(
      studioProvider(widget.id).select((s) => s.valueOrNull?.studio),
    );

    return PageLayout(
      topBar: const TopBar(),
      floatingBar: FloatingBar(
        scrollCtrl: _ctrl,
        children: [
          if (studio != null) ...[
            _FavoriteButton(studio),
            _FilterButton(widget.id),
          ],
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Consts.layoutBig),
            child: Consumer(
              builder: (context, ref, _) {
                ref.listen<AsyncValue>(
                  studioProvider(widget.id),
                  (_, s) {
                    if (s.hasError)
                      showPopUp(
                        context,
                        ConfirmationDialog(
                          title: 'Could not load studio',
                          content: s.error.toString(),
                        ),
                      );
                  },
                );

                final name = studio?.name ?? widget.name;
                final titleWidget = name != null
                    ? SliverToBoxAdapter(
                        child: GestureDetector(
                          onTap: () => Toast.copy(context, name),
                          child: Hero(
                            tag: widget.id,
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.headline1,
                            ),
                          ),
                        ),
                      )
                    : null;

                return ref
                    .watch(studioProvider(widget.id))
                    .unwrapPrevious()
                    .when(
                      loading: () => CustomScrollView(
                        physics: Consts.physics,
                        slivers: [
                          refreshControl,
                          if (titleWidget != null) titleWidget,
                          const SliverFillRemaining(
                            child: Center(child: Loader()),
                          ),
                        ],
                      ),
                      error: (_, __) => CustomScrollView(
                        physics: Consts.physics,
                        slivers: [
                          refreshControl,
                          if (titleWidget != null) titleWidget,
                          const SliverFillRemaining(
                            child: Center(child: Text('Could not load studio')),
                          ),
                        ],
                      ),
                      data: (data) {
                        final items = <Widget>[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 20),
                              child: Text(
                                '${data.studio.favorites.toString()} favourites',
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                            ),
                          )
                        ];
                        final sort =
                            ref.watch(studioFilterProvider(widget.id)).sort;

                        if (sort == MediaSort.START_DATE ||
                            sort == MediaSort.START_DATE_DESC ||
                            sort == MediaSort.END_DATE ||
                            sort == MediaSort.END_DATE_DESC) {
                          for (int i = 0; i < data.categories.length; i++) {
                            items.add(SliverToBoxAdapter(
                              child: Text(
                                data.categories.keys.elementAt(i),
                                style: Theme.of(context).textTheme.headline2,
                              ),
                            ));

                            final beg = data.categories.values.elementAt(i);
                            final end = i < data.categories.length - 1
                                ? data.categories.values.elementAt(i + 1)
                                : data.media.items.length;

                            items.add(
                              MediaGrid(data.media.items.sublist(beg, end)),
                            );
                          }
                        } else {
                          items.add(MediaGrid(data.media.items));
                        }

                        return CustomScrollView(
                          physics: Consts.physics,
                          controller: _ctrl,
                          slivers: [
                            refreshControl,
                            titleWidget!,
                            ...items,
                            SliverFooter(loading: data.media.hasNext),
                          ],
                        );
                      },
                    );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  _FavoriteButton(this.data);

  final Studio data;

  @override
  State<_FavoriteButton> createState() => __FavoriteButtonState();
}

class __FavoriteButtonState extends State<_FavoriteButton> {
  @override
  Widget build(BuildContext context) {
    return ActionButton(
      icon: widget.data.isFavorite ? Icons.favorite : Icons.favorite_border,
      tooltip: widget.data.isFavorite ? 'Unfavourite' : 'Favourite',
      onTap: () {
        setState(
          () => widget.data.isFavorite = !widget.data.isFavorite,
        );
        toggleFavoriteStudio(widget.data.id).then((ok) {
          if (!ok) {
            setState(
              () => widget.data.isFavorite = !widget.data.isFavorite,
            );
          }
        });
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  _FilterButton(this.id);

  final int id;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return ActionButton(
          icon: Ionicons.funnel_outline,
          tooltip: 'Filter',
          onTap: () {
            var filter = ref.read(studioFilterProvider(id));

            final sortItems = <String, int>{};
            for (int i = 0; i < MediaSort.values.length; i += 2) {
              String key = Convert.clarifyEnum(MediaSort.values[i].name)!;
              sortItems[key] = i ~/ 2;
            }

            final onDone = (_) =>
                ref.read(studioFilterProvider(id).notifier).state = filter;

            showSheet(
              context,
              OpaqueSheet(
                initialHeight: Consts.tapTargetSize * 4,
                builder: (context, scrollCtrl) => GridView(
                  controller: scrollCtrl,
                  physics: Consts.physics,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 20,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithMinWidthAndFixedHeight(
                    minWidth: 155,
                    height: 75,
                  ),
                  children: [
                    DropDownField<int>(
                      title: 'Sort',
                      value: filter.sort.index ~/ 2,
                      items: sortItems,
                      onChanged: (val) {
                        int index = val * 2;
                        if (filter.sort.index % 2 != 0) index++;
                        filter = filter.copyWith(sort: MediaSort.values[index]);
                      },
                    ),
                    DropDownField<bool>(
                      title: 'Order',
                      value: filter.sort.index % 2 == 0,
                      items: const {'Ascending': true, 'Descending': false},
                      onChanged: (val) {
                        int index = filter.sort.index;
                        if (!val && index % 2 == 0) {
                          index++;
                        } else if (val && index % 2 != 0) {
                          index--;
                        }
                        filter = filter.copyWith(sort: MediaSort.values[index]);
                      },
                    ),
                    DropDownField<bool?>(
                      title: 'List Filter',
                      value: filter.onList,
                      items: const {
                        'Everything': null,
                        'On List': true,
                        'Not On List': false,
                      },
                      onChanged: (val) =>
                          filter = filter.copyWith(onList: () => val),
                    ),
                    DropDownField<bool?>(
                      title: 'Main Studio',
                      value: filter.isMain,
                      items: const {
                        'Doesn\'t matter': null,
                        'Is Main': true,
                        'Is Not Main': false,
                      },
                      onChanged: (val) =>
                          filter = filter.copyWith(isMain: () => val),
                    ),
                  ],
                ),
              ),
            ).then(onDone);
          },
        );
      },
    );
  }
}
