import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';
import 'package:otraku/controllers/collection.dart';
import 'package:otraku/controllers/user.dart';
import 'package:otraku/enums/themes.dart';
import 'package:otraku/models/anilist/user_model.dart';
import 'package:otraku/pages/pushable/user_activities_page.dart';
import 'package:otraku/pages/pushable/favourites_page.dart';
import 'package:otraku/pages/settings/settings_page.dart';
import 'package:otraku/pages/home/home_page.dart';
import 'package:otraku/controllers/config.dart';
import 'package:otraku/pages/home/collection_tab.dart';
import 'package:otraku/helpers/client.dart';
import 'package:otraku/tools/fade_image.dart';
import 'package:otraku/tools/navigation/custom_nav_bar.dart';
import 'package:otraku/tools/navigation/custom_sliver_header.dart';
import 'package:otraku/tools/overlays/dialogs.dart';

class UserTab extends StatelessWidget {
  static const ROUTE = '/user';

  final int id;
  final String avatarUrl;

  const UserTab(this.id, this.avatarUrl);

  @override
  Widget build(BuildContext context) {
    final sidePadding = MediaQuery.of(context).size.width > 515
        ? (MediaQuery.of(context).size.width - 500) / 2.0
        : 10.0;

    return GetBuilder<User>(
      tag: id?.toString() ?? Client.viewerId.toString(),
      builder: (user) => CustomScrollView(
        physics: Config.PHYSICS,
        slivers: [
          _Header(
            id: id ?? Client.viewerId,
            user: user.model,
            isMe: id == null,
            avatarUrl: avatarUrl,
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              left: sidePadding,
              right: sidePadding,
              top: 15,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(
                [
                  Container(
                    height: Config.MATERIAL_TAP_TARGET_SIZE,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: Config.BORDER_RADIUS,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            FluentSystemIcons.ic_fluent_comment_filled,
                            color: Theme.of(context).accentColor,
                          ),
                          onPressed: () => Get.toNamed(
                            UserActivitiesPage.ROUTE,
                            arguments: id,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            FluentSystemIcons.ic_fluent_movies_and_tv_filled,
                            color: Theme.of(context).accentColor,
                          ),
                          onPressed: () => id == null
                              ? Get.find<Config>().pageIndex =
                                  HomePage.ANIME_LIST
                              : _pushCollection(true),
                        ),
                        IconButton(
                          icon: Icon(
                            FluentSystemIcons.ic_fluent_bookmark_filled,
                            color: Theme.of(context).accentColor,
                          ),
                          onPressed: () => id == null
                              ? Get.find<Config>().pageIndex =
                                  HomePage.MANGA_LIST
                              : _pushCollection(false),
                        ),
                        IconButton(
                          icon: Icon(
                            FluentSystemIcons.ic_fluent_heart_filled,
                            color: Theme.of(context).accentColor,
                          ),
                          onPressed: () => Get.toNamed(
                            FavouritesPage.ROUTE,
                            arguments: id,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (user.model?.description != null)
                    Container(
                      padding: Config.PADDING,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: Config.BORDER_RADIUS,
                      ),
                      child: HtmlWidget(
                        user.model.description,
                        textStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyText1.color,
                        ),
                      ),
                    ),
                  SizedBox(height: CustomNavBar.offset(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pushCollection(bool ofAnime) {
    final collectionTag = '${ofAnime ? Collection.ANIME : Collection.MANGA}$id';
    Get.toNamed(
      CollectionTab.ROUTE,
      arguments: [id, ofAnime, collectionTag],
      preventDuplicates: false,
    );
  }
}

class _Header extends StatelessWidget {
  final int id;
  final UserModel user;
  final bool isMe;
  final String avatarUrl;

  _Header({
    @required this.id,
    @required this.user,
    @required this.isMe,
    @required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    const avatarSize = 150.0;
    double bannerHeight = MediaQuery.of(context).size.width * 0.6;
    if (bannerHeight > 400) bannerHeight = 400;
    final height = bannerHeight + avatarSize * 0.5;
    final avatar = avatarUrl ?? user?.avatar;

    return CustomSliverHeader(
      height: height,
      implyLeading: !isMe,
      actionsScrollFadeIn: false,
      title: user?.name,
      actions: [
        if (isMe)
          IconShade(IconButton(
            icon: const Icon(FluentSystemIcons.ic_fluent_settings_regular),
            color: Theme.of(context).dividerColor,
            onPressed: () => Get.toNamed(SettingsPage.ROUTE),
          ))
        else if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: FlatButton(
              child: Text(
                user.following ? 'Unfollow' : 'Follow',
                style: Theme.of(context)
                    .textTheme
                    .button
                    .copyWith(fontSize: Styles.FONT_SMALL),
              ),
              color: Theme.of(context).accentColor,
              onPressed: Get.find<User>(tag: id.toString()).toggleFollow,
            ),
          )
      ],
      background: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: Theme.of(context).primaryColor),
                    if (user?.banner != null)
                      FadeImage(user.banner, height: bannerHeight)
                  ],
                ),
              ),
              SizedBox(height: height - bannerHeight),
            ],
          ),
          Positioned.fill(
            bottom: height - bannerHeight - 1,
            child: Container(
              height: bannerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Theme.of(context).backgroundColor,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            avatar != null
                ? GestureDetector(
                    child: Hero(
                      tag: id,
                      child: ClipRRect(
                        borderRadius: Config.BORDER_RADIUS,
                        child: Container(
                          height: avatarSize,
                          width: avatarSize,
                          child: FadeImage(avatar, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => PopUpAnimation(
                        ImageDialog(Image.network(avatar, fit: BoxFit.cover)),
                      ),
                    ),
                  )
                : SizedBox(width: avatarSize),
            const SizedBox(width: 10),
            if (user?.name != null)
              Text(
                user.name,
                style: Theme.of(context).textTheme.headline3,
              ),
          ],
        ),
      ),
    );
  }
}
