import 'package:challo/models/link_to.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Setting

String tokenServerUrl = '';
String mergedBucketBaseUrl = '';
String transcodingAPIURL = '';
String roboAvatarAPIURL = '';
String roboImagesBucketBaseUrl = '';

// Dark Color palette
const kBackgroundColorDark = Color(0xFF16161a);
const kBackgroundColorDark2 = Color(0xFF242629);
const kHeadlineColorDark = Color(0xFFfffffe);
const kHeadlineColorDarkShade = Color.fromARGB(255, 3, 3, 2);
const kIconSecondaryColorDark = Color(0xFF72757e);
const kParaColorDark = Color(0xFF94a1b2);
const kParaColorDarkTint = Color(0xFFb7bfcb);
const kPrimaryColor = Color(0xFF7f5af0);
const kPrimaryColorTint2 = Color(0xFFbfacf7);
const kPrimaryColorTint = Color(0xFF8b6af1);
const kWarningColorDark = Color(0xFFCC0000);
const kWarningColorDarkTint = Color(0xFFe06666);
const kOverlayColorDark2 = Color(0xFF505154);
const kSubTextColor = Color(0xFFb2b2b1);
const kTertiaryColor = Color(0xFF2cb67d);
const kTertiaryColorShade = Color(0xFF267652);
const kMessageBubbleColor2 = Color(0xFF412f71);
const kMessageBubbleColor1 = Color(0xFFafb0b1);

//Color kPrimaryColor = const Color(0xFF4267B2);

const kDarkPrimaryColor = Color(0xFF7f5af0);
const kDarkPink = Color(0xFFffafcc);
const kLightPink = Color(0xFFffc8dd);
const kVerifiedColor = Color(0xFFcdb4db);
const kBlackContrast = Color(0xFF18191F);
const kCardBackgroundColor = Color(0xFF1F1F1F);
const kSecondaryCardBackgroundColor = Color(0xFF2B263E);
const kSecondaryLightColor = Color(0xFFE4E9F2);
const kSecondaryDarkColor = Color(0xFF404040);
const kAccentLightColor = Color(0xFFB3BFD7);
const kAccentDarkColor = Color(0xFF4E4E4E);
//const kBackgroundColorDark = Color(0xFF3A3A3A);
const kSurfaceDarkColor = Color(0xFF222225);
// Icon Colors
const kAccentIconLightColor = Color(0xFFECEFF5);
const kAccentIconDarkColor = Color(0xFF303030);
const kPrimaryIconLightColor = Color(0xFFECEFF5);
const kPrimaryIconDarkColor = Color(0xFF232323);
// Text Colors
const kBodyTextColorLight = Color(0xFFA1B0CA);
const kBodyTextColorDark = Color(0xFF94a1b2);
const kTitleTextLightColor = Color(0xFF101112);
const kTitleTextDarkColor = Color(0xFFfffffe);

const kShadowColor = Color(0xFF364564);

bool noInternetDisplayed = false;
bool hidenav = false;
bool connected = false;
bool whetherStreaming = false;

int selectedTabIndex = 0;

LinkTo? linkedPage;

LinkTo? preLinkedPage;

String appVersionName = '2.1.2+33';

String privacypolicy =
    '''Challo is a Free app. This SERVICE is provided by us at no cost and is intended for use as is.

This page is used to inform visitors regarding our policies with the collection, use, and disclosure of Personal Information if anyone decided to use our Service.

If you choose to use our Service, then you agree to the collection and use of information in relation to this policy. The Personal Information that we collect is used for providing and improving the Service. We will not use or share your information with anyone except as described in this Privacy Policy.

The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which is accessible at Challo unless otherwise defined in this Privacy Policy.

Information Collection and Use

For a better experience, while using our Service, we may require you to provide us with certain personally identifiable information, including but not limited to Email, Name, Profile Picture, Advertising ID. The information that we request will be retained by us and used as described in this privacy policy.

The app does use third party services that may collect information used to identify you.

Log Data

We want to inform you that whenever you use our Service, in a case of an error in the app we collect data and information (through third party products) on your phone called Log Data. This Log Data may include information such as your device Internet Protocol (“IP”) address, device name, operating system version, the configuration of the app when utilizing our Service, the time and date of your use of the Service, and other statistics.

Cookies

Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device's internal memory.

This Service does not use these “cookies” explicitly. However, the app may use third party code and libraries that use “cookies” to collect information and improve their services. You have the option to either accept or refuse these cookies and know when a cookie is being sent to your device. If you choose to refuse our cookies, you may not be able to use some portions of this Service.

Service Providers

We may employ third-party companies and individuals due to the following reasons:

To facilitate our Service;

To provide the Service on our behalf;

To perform Service-related services; or

To assist us in analyzing how our Service is used.

We want to inform users of this Service that these third parties have access to your Personal Information. The reason is to perform the tasks assigned to them on our behalf. However, they are obligated not to disclose or use the information for any other purpose.

Security

We value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and we cannot guarantee its absolute security.

Links to Other Sites

This Service may contain links to other sites. If you click on a third-party link, you will be directed to that site. Note that these external sites are not operated by us. Therefore, we strongly advise you to review the Privacy Policy of these websites. We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services.

Children’s Privacy

These Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13 years of age. In the case we discover that a child under 13 has provided us with personal information, we immediately delete this from our servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we will be able to do necessary actions.

Changes to This Privacy Policy

We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page.

This policy is effective as of 2021-07-18

Contact Us

If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at contact@challo.tv.''';

String termsconditions =
    '''By downloading or using the app, these terms will automatically apply to you – you should make sure therefore that you read them carefully before using the app. You’re not allowed to copy, or modify the app, any part of the app, or our trademarks in any way. 
    
You’re not allowed to attempt to extract the source code of the app, and you also shouldn’t try to translate the app into other languages, or make derivative versions. The app itself, and all the trade marks, copyright, database rights and other intellectual property rights related to it, still belong to Challo.

Challo is committed to ensuring that the app is as useful and efficient as possible. For that reason, we reserve the right to make changes to the app or to charge for its services, at any time and for any reason. We will never charge you for the app or its services without making it very clear to you exactly what you’re paying for.

The Challo app stores and processes personal data that you have provided to us, in order to provide our Service. It’s your responsibility to keep your phone and access to the app secure. We therefore recommend that you do not jailbreak or root your phone, which is the process of removing software restrictions and limitations imposed by the official operating system of your device. It could make your phone vulnerable to malware/viruses/malicious programs, compromise your phone’s security features and it could mean that the Challo app won’t work properly or at all.

The app does use third party services that declare their own Terms and Conditions.

You should be aware that there are certain things that Challo will not take responsibility for. Certain functions of the app will require the app to have an active internet connection. The connection can be Wi-Fi, or provided by your mobile network provider, but Challo cannot take responsibility for the app not working at full functionality if you don’t have access to Wi-Fi, and you don’t have any of your data allowance left.

If you’re using the app outside of an area with Wi-Fi, you should remember that your terms of the agreement with your mobile network provider will still apply. As a result, you may be charged by your mobile provider for the cost of data for the duration of the connection while accessing the app, or other third party charges. In using the app, you’re accepting responsibility for any such charges, including roaming data charges if you use the app outside of your home territory (i.e. region or country) without turning off data roaming. If you are not the bill payer for the device on which you’re using the app, please be aware that we assume that you have received permission from the bill payer for using the app.

Along the same lines, Challo cannot always take responsibility for the way you use the app i.e. You need to make sure that your device stays charged – if it runs out of battery and you can’t turn it on to avail the Service, Challo cannot accept responsibility.

With respect to Challo’s responsibility for your use of the app, when you’re using the app, it’s important to bear in mind that although we endeavour to ensure that it is updated and correct at all times, we do rely on third parties to provide information to us so that we can make it available to you. Challo accepts no liability for any loss, direct or indirect, you experience as a result of relying wholly on this functionality of the app.

At some point, we may wish to update the app. The app is currently available on Android & iOS – the requirements for both systems(and for any additional systems we decide to extend the availability of the app to) may change, and you’ll need to download the updates if you want to keep using the app. Challo does not promise that it will always update the app so that it is relevant to you and/or works with the Android & iOS version that you have installed on your device. However, you promise to always accept updates to the application when offered to you, We may also wish to stop providing the app, and may terminate use of it at any time without giving notice of termination to you. Unless we tell you otherwise, upon any termination, (a) the rights and licenses granted to you in these terms will end; (b) you must stop using the app, and (if needed) delete it from your device.

Changes to This Terms and Conditions

We may update our Terms and Conditions from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Terms and Conditions on this page.

These terms and conditions are effective as of 2021-07-18

Contact Us

If you have any questions or suggestions about our Terms and Conditions, do not hesitate to contact us at contact@challo.tv.''';

String ugcRules =
    '''UGC refers to User Generated Content. These are the rules that apply to videos, live streams, pictures, textual, audio, comments, communities, and any other User Generated Content (UGC) you submit to Challo. Read these rules carefully as they contain
important information regarding how you may use Challo services and how Challo may use your content.

Note: If you believe any Content has infringed or violated your rights, including by defaming or infringing your copyright, or if you find something inappropriate, please report it immediately through the 'Report this Content' (or the 'Report this Comment' in case of comments) feature in the app/website. Alternatively, you can also send an email to report@challo.tv.

Submissions
1.1. You are entirely responsible for Content submitted by you. You agree and confirm that you will abide by the following in relation to any Content you submit:
a) Before featuring anyone else in your submissions, you must have obtained their consent to film or photograph them and to submit the Content to Challo.
b) Everything you submit should be your original content (OC) and not copied from anyone else's.
By submitting Content you agree and confirm that your submission does not infringe the copyright or any other rights of any 3rd party. If you include anyone else's material in your submission, you must have obtained their permission to do so. If you don't, you may be infringing the copyright in the material. This includes materials downloaded or copied from a website.
c) Do not include anything that is illegal, sexually explicit, obscene, indecent, harassing, threatening, or offensive in nature.
d) Do not mention any court cases or arrests -- this could constitute contempt of court.
e) Do not include anything about any living person or business which is defamatory, libelous, or slanderous.
f) Do not include anything which is racist, abusive, malicious, or derogatory (toward an individual or a business entity).
g) Do not submit anything confidential, covertly film or photograph anyone or infringe anyone's right to privacy.
h) Ensure nothing in your Content promotes, show, or encourage cruelty, bullying, violence, vandalism, fraudulent or criminal acts.
i) Do not include videos, images, or descriptions of anything which would cause physical harm to anyone if replicated.
j) Do not include your personal details (addresses, phone numbers, etc.) or anyone else's in your Content.
k) Content must not feature predominantly or solely a trademark or logo.
l) Nothing in the Content must be offensive or derogatory to any person or group based on their race, ethnicity, skin color, sexual orientation, gender, or religion.
m) Content must not be submitted for advertising, promotional, lobbying, or other commercial purposes.
n) No content should feature celebrities or public figures unless you have their permission or if you are the celebrity or the public figure in question.
o) Content should not bring Challo into disrepute.
p) No nudity, sexual activity, or foul language may be permitted in the Content.
q) You must've obtained (and continue to hold) all consents and licenses required for legally submitting the Content and for it to be used on Challo.
 r) If any under 16s are shown in the Content, the written consent of their parent or guardian must be obtained.
s) Content must be free from viruses, Trojans, or other harmful elements.
t) Participation in any Content is at your own risk.
u) No sums are payable to any person with respect to the grant of rights at Condition 3 save as specified in that clause.
v) You may be held legally accountable for your submission if you are in breach of the rules listed above.

1.2 You agree that Challo may suspend or terminate your account, at any time and without notice, if Challo believes that you have violated or acted inconsistently with the letter or spirit of these rules, or for any other reason.

1.3 All decisions by Challo are final and no correspondence will be entered into.

1.4 Your Content is submitted to Challo for consideration for inclusion on the Challo app and/or website and it shall be displayed to and accessible by Challo users. Accordingly, it shall not be confidential.

1.5 Your submission may be created in any digital format. Challo accepts no responsibility for loss or damage or delay of Content during the upload process.

1.6 Your content is made at your own expense and Challo shall not be liable to reimburse any expenses incurred in making a submission.

1.7 Challo may review the Content you submit to the app/website but do not undertake to do so. Challo may reject or accept your Content for any reason at its absolute discretion. If your Content contains what appears to be illegal conduct, Challo may inform law enforcement authorities.

2. Rights to your Content
2.1 You retain ownership in your Content.

2.2 You irrevocably and unconditionally grant to Challo (and those authorized by it) all necessary rights and consents for the full period of copyright to use any Content you submit, for any purposes including without limitation the ability for Challo to digitize, encode, publish, and transmit the Content across apps and websites owned or controlled by it or by its partners. Challo and/or its partners may use your Content in any way in any media (including promotional material, associated services, and any other ancillary use) and in any part of the world through any medium now known or hereinafter invented. Such right to use is royalty-free and no payment is, or shall be, due to you.

2.3 You grant Challo the non-exclusive right to syndicate to third-party websites or services.

2.4 You permit Challo or its third-party agents to edit or change the Content in any way that it deems necessary in its sole discretion.

2.5 You irrevocably and unconditionally waive any so-called "moral rights" or "performers rights" in the Content (as stated in the Copyright, Designs and Patents Act 1988 or otherwise) that you now have or may acquire in relation to the Content.

2.6 Any material created by or on behalf of Challo utilizing your Content or any component therein is and shall remain the property of Challo, but for clarity, you retain ownership of your Content.

3. Limitation of Liability and Indemnity
3.1 Challo does not endorse any Content or any opinion, recommendation, or advice contained therein and Challo disclaims any liability in connection with Content.

3.2 Challo accepts no liability for any misuse of intellectual property rights.

3.3 You agree that under no circumstances will Challo or its partners be responsible or liable to you or any other person or entity for direct, indirect, incidental, consequential, or other damages (including, but not limited to, damages for loss of profits, goodwill, use, data, or other intangible losses) arising out of or relating in any way to Challo, the use or the inability to use the service, unauthorized access to or alteration of your transmission of data, the materials available on or through the site, even if any of these parties have been advised of the possibility of any damages.

4 Your password where a service required the use of a password: You must not under any circumstance allow any other person to access your Challo account using your password. In the event that your password is learned by another person, you must immediately reset it. You are responsible for all actions (including misuse or breach of UGC rules) that take place as a result of the use of Challo by means of your shared account credentials.

5 Publicity: You grant Challo the right to issue publicity concerning your Content and to use it for such purposes your name, username, and other details provided at the time of registration and/or submission. You agree to participate in publicity as reasonably requested.

6 Intellectual Property Rights related to Challo and the User Generated Content: The names, images, and logos identifying Challo or its partners and their products or services are proprietary marks of Challo and its associated partners and/or third parties. All copyright, trademarks, and other intellectual property rights (including the design, arrangement, look, and feel) and all material or Content supplied (apart from your and other users' Content) shall remain at all times the property of Challo or its licensors.

7 To make a Complaint: If you believe any Content has infringed or violated your rights, including by defaming or infringing your copyright, please report it immediately through the 'Report this Content' (or the 'Report this Comment' in case of comments) feature in the app/website. Alternatively, you can also send an email to report@challo.tv. Challo shall endeavor to promptly remove the Content that doesn't follow the stated User Generated Content rules.

8 Challo reserves the right to review and revise these rules from time to time and the changes are effective immediately after being updated on the app or website. By using/accessing Challo services subsequently to any revision of these rules, you agree to be bound by such changes. You should periodically check the terms for changes.
''';

mystyle(double size,
    [Color color = Colors.white, FontWeight fw = FontWeight.w700]) {
  return GoogleFonts.roboto(
    fontSize: size,
    color: color,
    fontWeight: fw,
  );
}

//montserrat

markdownStyleSheetforLits(BuildContext context) {
  return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
    h1: Theme.of(context).textTheme.headline1!.copyWith(
          fontSize: 25.0,
          color: Colors.grey.shade100,
          fontWeight: FontWeight.w700,
        ),
    h1Padding: const EdgeInsets.only(top: 5.0, bottom: 3.0),
    h2: Theme.of(context).textTheme.headline1!.copyWith(
          fontSize: 20.0,
          color: Colors.grey.shade100,
          fontWeight: FontWeight.w700,
        ),
    h2Padding: const EdgeInsets.only(top: 5.0, bottom: 3.0),
    h3: Theme.of(context).textTheme.headline1!.copyWith(
          fontSize: 18.0,
          color: Colors.grey.shade100,
          fontWeight: FontWeight.w700,
        ),
    h3Padding: const EdgeInsets.only(top: 5.0, bottom: 3.0),
    p: Theme.of(context).textTheme.subtitle1!.copyWith(
          fontSize: 17.0,
          color: kParaColorDarkTint,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          //wordSpacing: 1.0,
        ),
    pPadding: const EdgeInsets.only(bottom: 3.0),
    a: Theme.of(context).textTheme.subtitle1!.copyWith(
          fontSize: 17.0,
          color: kPrimaryColorTint2,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.41,
          //wordSpacing: 1.0,
        ),
    blockquotePadding: const EdgeInsets.only(
      left: 10,
      bottom: 3.0,
    ),
    blockquoteDecoration: const BoxDecoration(
      border: Border(
        left: BorderSide(color: kPrimaryColor, width: 4),
      ),
    ),
  );
}

styleSheetforMarkdown(BuildContext context) {
  return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
    h1: Theme.of(context).textTheme.headline1!.copyWith(
          fontSize: 25.0,
          color: Colors.grey.shade100,
          fontWeight: FontWeight.w700,
        ),
    h1Padding: const EdgeInsets.only(top: 5.0, bottom: 3.0),
    h2: Theme.of(context).textTheme.headline1!.copyWith(
          fontSize: 20.0,
          color: Colors.grey.shade100,
          fontWeight: FontWeight.w700,
        ),
    h2Padding: const EdgeInsets.only(top: 5.0, bottom: 3.0),
    h3: Theme.of(context).textTheme.headline1!.copyWith(
          fontSize: 18.0,
          color: Colors.grey.shade100,
          fontWeight: FontWeight.w700,
        ),
    h3Padding: const EdgeInsets.only(top: 5.0, bottom: 3.0),
    p: Theme.of(context).textTheme.subtitle1!.copyWith(
          fontSize: 15.0,
          color: kParaColorDarkTint,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.24,
          //wordSpacing: 1.0,
        ),
    pPadding: const EdgeInsets.only(bottom: 3.0),
    a: Theme.of(context).textTheme.subtitle1!.copyWith(
          fontSize: 15.0,
          color: kPrimaryColorTint2,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.24,
          //wordSpacing: 1.0,
        ),
    blockquotePadding: const EdgeInsets.only(
      left: 10,
      bottom: 3.0,
    ),
    blockquoteDecoration: const BoxDecoration(
      border: Border(
        left: BorderSide(color: kPrimaryColor, width: 4),
      ),
    ),
  );
}

String defaultUserPic =
    'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645';

var usercollection = FirebaseFirestore.instance.collection('users');
//var videoscollection = FirebaseFirestore.instance.collection('content');
var livevideoscollection = FirebaseFirestore.instance.collection('livevideos');
var contentcollection =
    FirebaseFirestore.instance.collection('contentcollection');
var archivedvideoscollection =
    FirebaseFirestore.instance.collection('archivedvideos');
var bugreportcollection = FirebaseFirestore.instance.collection('bugreports');
var directcontactcollection =
    FirebaseFirestore.instance.collection('directcontact');
var commentreportcollection =
    FirebaseFirestore.instance.collection('commentreports');
var contentreportcollection =
    FirebaseFirestore.instance.collection('contentreports');
var userreportcollection = FirebaseFirestore.instance.collection('userreports');
var accountDeletionCollection =
    FirebaseFirestore.instance.collection('accountDeletions');
var communityreportcollection =
    FirebaseFirestore.instance.collection('communityreports');
var communitycollection =
    FirebaseFirestore.instance.collection('communitycollection');
var suggestionscollection =
    FirebaseFirestore.instance.collection('searchqueries');
var chatscollection = FirebaseFirestore.instance.collection('chatscollection');
var litscollection = FirebaseFirestore.instance.collection('lits');
Reference videosfolder = FirebaseStorage.instance.ref().child('content');
Reference imagesfolder = FirebaseStorage.instance.ref().child('images');
DatabaseReference realtimeDatabase = FirebaseDatabase.instance.ref();

//realtimedb variables
final chatsdb = FirebaseDatabase.instance.ref().child('chatsdb');
final commentsdb = FirebaseDatabase.instance.ref().child('commentsdb');
final litsdb = FirebaseDatabase.instance.ref().child('litsdb');

//text styles

styleTitleSmall({
  double fontSize = 17.0,
  FontWeight fontWeight = FontWeight.w500,
  Color color = kHeadlineColorDark,
  double letterSpacing = -0.41,
}) {
  return GoogleFonts.lato(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

styleSubTitleSmall({
  double fontSize = 15.0,
  FontWeight fontWeight = FontWeight.w400,
  Color color = kParaColorDark,
  double letterSpacing = -0.24,
}) {
  return GoogleFonts.lato(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

styleReallyLargeTitle({
  double fontSize = 34.0,
  FontWeight fontWeight = FontWeight.w700,
  Color color = kHeadlineColorDark,
  double letterSpacing = 0.41,
}) {
  return GoogleFonts.lato(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
