import 'package:admin_app/ui/theatres/seat.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_disposebag/flutter_disposebag.dart';
import 'package:flutter_provider/flutter_provider.dart';
import 'package:utils/utils.dart';

import '../domain/model/movie.dart';
import '../domain/model/theatre.dart';
import '../domain/model/user.dart';
import '../domain/repository/user_repository.dart';
import '../ui/movies/movie_info.dart';
import '../ui/movies/upload_movie/movie_upload_bloc.dart';
import '../ui/movies/upload_movie/movie_upload_page.dart';
import '../ui/show_times/select_movie_page.dart';
import '../ui/show_times/show_times_page.dart';
import '../ui/show_times/ticket_page.dart';
import '../ui/theatres/add/add_theatre_page.dart';
import '../ui/theatres/theatre_page.dart';
import 'app_scaffold.dart';
import 'home/home_page.dart';
import 'login_update_profile/login_update_profile_page.dart';
import 'movies/movie_bloc.dart';
import 'movies/movies_page.dart';
import 'profile/profile_page.dart';
import 'qr/qrcode_page.dart';
import 'report/report_page.dart';
import 'show_times/add_show_time_page.dart';
import 'theatres/add/seats_page.dart';
import 'theatres/theatre_info_page.dart';
import 'users/manager_users_bloc.dart';
import 'users/manager_users_page.dart';

class MainPage extends StatefulWidget {
  static const routeName = '/main';

  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with DisposeBagMixin {
  static final homeRoutes = <String, AppScaffoldWidgetBuilder>{
    Navigator.defaultRouteName: (context, settings) => const HomePage(),
    ManagerUsersPage.routeName: (context, setting) {
      return BlocProvider<ManagerUsersBloc>(
        child: const ManagerUsersPage(),
        initBloc: (context) => ManagerUsersBloc(context.get()),
      );
    },
    MoviePage.routeName: (context, setting) {
      return BlocProvider<MovieBloc>(
        child: const MoviePage(),
        initBloc: (context) => MovieBloc(context.get()),
      );
    },
    MovieInfoPage.routeName: (context, setting) {
      return MovieInfoPage(movie: setting.arguments as Movie);
    },
    UploadMoviePage.routeName: (context, setting) {
      return BlocProvider<MovieUploadBloc>(
        child: UploadMoviePage(),
        initBloc: (context) => MovieUploadBloc(context.get()),
      );
    },
    TheatresPage.routeName: (context, setting) {
      return TheatresPage(mode: setting.arguments as TheatresMode);
    },
    TheatreInfoPage.routeName: (context, settings) {
      return TheatreInfoPage(theatre: settings.arguments as Theatre);
    },
    AddTheatrePage.routeName: (context, settings) {
      return AddTheatrePage();
    },
    SeatsPage.routeName: (context, settings) {
      //return SeatsPage(seats: settings.arguments);
      final BuiltList<TheatreSeat> seats =
          (settings.arguments as List<TheatreSeat>).build();
      return SeatsPage(seats: seats);
    },
    ShowTimesPage.routeName: (context, settings) {
      return ShowTimesPage(theatre: settings.arguments as Theatre);
    },
    SelectMoviePage.routeName: (context, settings) {
      return SelectMoviePage(theatre: settings.arguments as Theatre);
    },
    TicketsPage.routeName: (ctx, settings) {
      final args = settings.arguments as Map<String, dynamic>;
      return TicketsPage(showTime: args['showTime'], theatre: args['theatre']);
    },
    AppShowTimePage.routeName: (ctx, s) {
      final args = s.arguments as Map<String, dynamic>;
      return AppShowTimePage(
        theatre: args['theatre'],
        movie: args['movie'],
      );
    },
    ReportPage.routeName: (c, s) {
      return ReportPage(theatre: s.arguments as Theatre);
    },
    QRCodePage.routeName: (c, s) => QRCodePage(),
  };

  static final profileRoutes = <String, AppScaffoldWidgetBuilder>{
    Navigator.defaultRouteName: (context, settings) => ProfilePage(),
    UpdateProfilePage.routeName: (context, settings) {
      final args = settings.arguments;
      assert(args != null && args is User);
      return UpdateProfilePage(user: args as User);
    },
  };

  dynamic listenToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    listenToken ??= Provider.of<UserRepository>(context)
        .user$
        .where((userOptional) => userOptional != null && userOptional is None)
        .listen((event) =>
            // Navigator.of(context).pushNamedAndRemoveUntil(
            //       LoginPage.routeName,
            //       (route) => false,
            //     )
            print("==== HONG TODO: disable auto return to login page"))
        .disposedBy(bag);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      builders: [
        (context, settings) => homeRoutes[settings.name]!(context, settings),
        (context, settings) => profileRoutes[settings.name]!(context, settings),
      ],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
