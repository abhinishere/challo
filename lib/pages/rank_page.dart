import 'package:challo/variables.dart';
import 'package:flutter/material.dart';

class RankPage extends StatefulWidget {
  const RankPage({Key? key}) : super(key: key);

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  rankIt(String docName, int priority) async {
    await contentcollection.doc(docName).update({
      'trendingpriority': priority,
    });
  }

  inAppReviewDisplayedFalse() async {
    await usercollection.get().then(
          (value) => value.docs.forEach(
            (element) {
              var docRef = usercollection.doc(element.id);

              docRef.update({
                'inAppReviewDisplayed': false,
              });
            },
          ),
        );
    print("in app review updated");
  }

  removeallRanks() async {
    await contentcollection.get().then(
          (value) => value.docs.forEach(
            (element) {
              var docRef = contentcollection.doc(element.id);

              docRef.update({
                'trendingpriority': 0,
              });
            },
          ),
        );
    print("all values updated");
  }

  rankCommunity() async {
    await communitycollection.get().then((value) =>
        value.docs.forEach((element) async {
          if (element.data()['memberuids'] != null &&
              List.from(element.data()['memberuids']).length > 3) {
            var docRef = communitycollection.doc(element.id);
            int featuredpriority =
                100 + List.from(element.data()['memberuids']).length;
            await docRef.update({
              'featuredpriority': featuredpriority,
            });
            print("featured priority of ${element.id} is $featuredpriority");
          }
        }));
  }

  litsRank(String litDoc, int trendingPriority) async {
    await litscollection.doc(litDoc).update({
      'trendingpriority': trendingPriority,
    });
  }

  rankAlgoAutomated() async {
    var currentTime = DateTime.now();
    List<String> docsExcluded = [
      'abhinFsMwS', 'pradeepanbestoYKpL1',
      //'devikashammy3hYK4',
    ];

    print('current timestamp is $currentTime');
    await contentcollection.get().then(
          (value) => value.docs.forEach(
            (element) async {
              DateTime timestamp = DateTime.now();
              int upvotes = 0;
              int downvotes = 0;
              int comments = 0;
              int trendingPriority = 0;

              //docNamewithTimestamp[element.id] = element.data()['time'];
              print(
                  'timestamps are ${element.data()['time'].millisecondsSinceEpoch}');
              if (element.data()['time'] != null) {
                timestamp = element.data()['time'].toDate();
                upvotes = element.data()['likes'].length ?? 0;
                downvotes = element.data()['dislikes'].length ?? 0;
                comments = element.data()['commentcount'] ?? 0;
              }

              if (currentTime.difference(timestamp).inHours < 96) {
                trendingPriority = trendingPriority + 500;
              } else if (currentTime.difference(timestamp).inHours < 120) {
                trendingPriority = trendingPriority + 250;
              } else {
                trendingPriority = trendingPriority + 0;
              }

              trendingPriority = trendingPriority +
                  (upvotes * 5) +
                  (downvotes * 2) +
                  (comments * 2);

              print("trending priority of ${element.id} is $trendingPriority");

              var docRef = contentcollection.doc(element.id);

              if (docsExcluded.contains(element.id)) {
                await docRef.update({
                  'trendingpriority': 0,
                });
              } else {
                await docRef.update({
                  'trendingpriority': trendingPriority,
                });
              }
            },
          ),
        );
    print("all data received");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: TextButton(
            child: const Text("Press"),
            onPressed: () {
              //removeallRanks();
              inAppReviewDisplayedFalse();
            },
          ),
        ),
      ),
    );
  }
}
