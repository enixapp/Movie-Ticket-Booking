import 'package:built_collection/built_collection.dart';
import 'package:disposebag/disposebag.dart';
import 'package:distinct_value_connectable_stream/distinct_value_connectable_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_disposebag/flutter_disposebag.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_loader/stream_loader.dart';
import 'package:tuple/tuple.dart';

import '../../../../domain/model/card.dart' as domain;
import '../../../../domain/repository/card_repository.dart';
import '../../../../utils/error.dart';
import '../../../../utils/utils.dart';
import '../../../app_scaffold.dart';
import '../../../widgets/empty_widget.dart';
import '../../../widgets/error_widget.dart';
import 'add_card/add_card_page.dart';

abstract class Message {}

class RemovedSuccess implements Message {
  final domain.Card removed;

  RemovedSuccess(this.removed);
}

class RemoveFailure implements Message {
  final domain.Card card;
  final Object error;

  RemoveFailure(this.card, this.error);
}

class CardsBloc extends DisposeCallbackBaseBloc {
  final ValueStream<Tuple2<LoaderState<BuiltList<domain.Card>>, domain.Card>>
      state$;
  final Stream<LoaderMessage<BuiltList<domain.Card>>> loaderMessage$;
  final Stream<Message> cardMessage$;

  final void Function() fetch;
  final Future<void> Function() refresh;
  final void Function(domain.Card) cardAdded;
  final void Function(domain.Card) removeCard;
  final void Function(domain.Card) selectedCard;

  CardsBloc._({
    @required this.state$,
    @required this.loaderMessage$,
    @required this.fetch,
    @required this.refresh,
    @required Future<void> Function() dispose,
    @required this.cardAdded,
    @required this.removeCard,
    @required this.selectedCard,
    @required this.cardMessage$,
  }) : super(dispose);

  factory CardsBloc(
    CardRepository cardRepository,
    domain.Card initialSelected,
  ) {
    DistinctValueConnectableStream<
        Tuple2<LoaderState<BuiltList<domain.Card>>, domain.Card>> state$;

    final cardMessageS = PublishSubject<Message>();
    final removeCardS = PublishSubject<domain.Card>();
    final selectedCardS = BehaviorSubject<domain.Card>.seeded(initialSelected);

    final cardAddedS = PublishSubject<domain.Card>();
    final removedCard$ = removeCardS.flatMap(
      (card) => cardRepository.removeCard(card).doOnData((removed) {
        final state = state$.value;
        if (state.item2?.id == removed.id) {
          selectedCardS.add(
              state.item1.content.where((i) => i.id != removed.id).firstOrNull);
        }
        cardMessageS.add(RemovedSuccess(removed));
      }).doOnError((e, s) {
        print(s);
        cardMessageS.add(RemoveFailure(card, e));
      }).onErrorResume((error) => Stream.empty()),
    );

    final cardStreamFunc = () => cardRepository.getCards().exhaustMap(
          (initial) => Rx.merge([
            removedCard$.map((removed) => Tuple2(removed, false)),
            cardAddedS.map((added) => Tuple2(added, true)),
          ])
              .scan<BuiltList<domain.Card>>(
                (acc, change, _) => change.item2
                    ? acc.rebuild((b) => b.add(change.item1))
                    : acc.rebuild(
                        (b) => b.removeWhere((i) => i.id == change.item1.id)),
                initial,
              )
              .startWith(initial),
        );

    final loader = LoaderBloc<BuiltList<domain.Card>>(
      loaderFunction: cardStreamFunc,
      initialContent: BuiltList.of(<domain.Card>[]),
      enableLogger: false,
    );

    state$ = Rx.combineLatest2(
      loader.state$,
      selectedCardS,
      (
        LoaderState<BuiltList<domain.Card>> state,
        domain.Card card,
      ) =>
          Tuple2(state, card),
    ).publishValueSeededDistinct(
        seedValue: Tuple2(loader.state$.value, selectedCardS.value));

    final bag = DisposeBag([
      state$.connect(),
      selectedCardS.listen((value) => print('[DEBUG] >>> selectedCard=$value')),
    ]);
    loader.fetch();

    return CardsBloc._(
      state$: state$,
      loaderMessage$: loader.message$,
      fetch: loader.fetch,
      refresh: loader.refresh,
      dispose: () async {
        await bag.dispose();
        await loader.dispose();
      },
      cardAdded: cardAddedS.add,
      removeCard: removeCardS.add,
      selectedCard: selectedCardS.add,
      cardMessage$: cardMessageS,
    );
  }
}

class CardsPage extends StatefulWidget {
  static const routeName = 'home/detail/tickets/combo/checkout/cards';

  @override
  _CardsPageState createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> with DisposeBagMixin {
  Object token;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  ValueStream<bool> fabVisible$;
  final listController = ScrollController();

  @override
  void initState() {
    super.initState();

    fabVisible$ = () {
      void Function() listener;
      PublishSubject<bool> controller;

      controller = PublishSubject<bool>(
        sync: true,
        onListen: () {
          listener = () {
            switch (listController.position.userScrollDirection) {
              case ScrollDirection.idle:
                controller.add(true);
                break;
              case ScrollDirection.forward:
                controller.add(true);
                break;
              case ScrollDirection.reverse:
                controller.add(false);
                break;
            }
          };
          listController.addListener(listener);
        },
        onCancel: () {
          listController.removeListener(listener);
          listController.dispose();
        },
      );

      final stream = controller.publishValueSeededDistinct(seedValue: true);
      stream.connect().disposedBy(bag);
      return stream;
    }();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    token ??= BlocProvider.of<CardsBloc>(context)
        .cardMessage$
        .listen(handleMessage)
        .disposedBy(bag);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<CardsBloc>(context);

    return WillPopScope(
      onWillPop: () async {
        final selected = bloc.state$.value.item2;
        print('[DEBUG] pop selected=$selected');

        AppScaffold.of(context).pop(selected);

        return false;
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text('Cards'),
        ),
        floatingActionButton: RxStreamBuilder<bool>(
          stream: fabVisible$,
          builder: (context, snapshot) {
            return Visibility(
              visible: snapshot.data,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final added = await AppScaffold.of(context)
                      .pushNamed(AddCardPage.routeName);
                  if (added != null) {
                    bloc.cardAdded(added as domain.Card);
                  }
                },
                label: Text('Add card'),
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: RxStreamBuilder<
            Tuple2<LoaderState<BuiltList<domain.Card>>, domain.Card>>(
          stream: bloc.state$,
          builder: (context, snapshot) {
            final state = snapshot.data.item1;

            if (state.isLoading) {
              return Center(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: LoadingIndicator(
                    color: Theme.of(context).accentColor,
                    indicatorType: Indicator.ballScaleMultiple,
                  ),
                ),
              );
            }

            if (state.error != null) {
              return Center(
                child: MyErrorWidget(
                  errorText: 'Error: ${getErrorMessage(state.error)}',
                  onPressed: bloc.fetch,
                ),
              );
            }

            final cards = state.content;
            if (cards.isEmpty) {
              return Center(
                child: EmptyWidget(
                  message: 'Empty cards',
                ),
              );
            }

            final selectedCard = snapshot.data.item2;
            return ListView.builder(
              controller: listController,
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];

                return InkWell(
                  onTap: () => bloc.selectedCard(card),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Image.asset(
                            card.imageName,
                            width: 128,
                            height: 84,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  card.card_holder_name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      .copyWith(fontSize: 17),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '•••• •••• •••• ' + card.last4,
                                  maxLines: 1,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      .copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            child: Column(
                              children: [
                                if (card.id == selectedCard?.id)
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.check_circle_sharp,
                                      color: const Color(0xff687189),
                                    ),
                                  )
                                else
                                  const SizedBox(
                                    width: 32,
                                    height: 32,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: const Color(0xff687189),
                                  ),
                                  onPressed: () => tapDelete(card, bloc),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void tapDelete(domain.Card card, CardsBloc bloc) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Remove card'),
          content: Text('Are you sure you want to remove card'),
          actions: <Widget>[
            FlatButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            FlatButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (identical(ok, true)) {
      bloc.removeCard(card);
    }
  }

  void handleMessage(Message msg) {
    if (msg is RemovedSuccess) {
      return scaffoldKey
          .showSnackBar("Removed success: '${msg.removed.last4}'");
    }

    if (msg is RemoveFailure) {
      return scaffoldKey.showSnackBar(
          "Remove '${msg.card.last4}' failed: ${getErrorMessage(msg.error)}");
    }
  }
}

extension on domain.Card {
  String get imageName {
    switch (brand) {
      case 'visa':
        return 'assets/images/visacard.png';
      case 'mastercard':
        return 'assets/images/mastercard.jpg';
      default:
        throw StateError('Not support type: $brand');
    }
  }
}