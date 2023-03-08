import 'package:challo/models/policy_model.dart';
import 'package:challo/pages/view_policy.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/text_only_button.dart';
import 'package:flutter/material.dart';

class PoliciesPage extends StatefulWidget {
  const PoliciesPage();

  @override
  State<PoliciesPage> createState() => _PoliciesPageState();
}

class _PoliciesPageState extends State<PoliciesPage> {
  final List<PolicyModel> policiesList = [
    PolicyModel(header: 'Privacy', body: privacypolicy),
    PolicyModel(header: 'Terms', body: termsconditions),
    PolicyModel(header: 'User Generated Content', body: ugcRules),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Policies"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              //IconTextButton(mainText: 'Privacy', subText: '', onPress: () {})
              TextOnlyButton(
                mainText: 'Terms',
                onPress: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: ((context) => ViewPolicy(
                              policyName: 'Terms & Conditions',
                              policyText: termsconditions))));
                },
              ),
              TextOnlyButton(
                mainText: 'Privacy',
                onPress: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: ((context) => ViewPolicy(
                              policyName: 'Privacy Policy',
                              policyText: privacypolicy))));
                },
              ),
              TextOnlyButton(
                mainText: 'User Generated Content',
                onPress: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: ((context) => ViewPolicy(
                              policyName: 'UGC Policy',
                              policyText: ugcRules))));
                },
                whetherborderbottom: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
