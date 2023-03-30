# Challo Flutter Social Media App

Built with Flutter and Firebase, Challo is a full-fledged social media app with a primary focus on live video-based discussions.

Live videos are hosted, recorded and then uploaded to Amazon S3 with the help of Agora token server API.

Meanwhile, other forms of content in the form of text posts, images, and non-live videos are uploaded to Firebase Storage.

Frequently accessed chats, comments, and data for LITS (Live Interactive Timeline Stories) feature are stored in Firebase Realtime Database.

Metadata of users, content, searches, etc. are stored in Firestore Database.

Overview of features:

- QnA, Debate and Podcast live video streaming
- Share links
- Publish text posts
- Post images and videos
- Create/join communities
- Add Lits. Live Interactive Timeline Stories, or Lits, lets you add timely updates to an ongoing event as a series of markdown posts and includes live chats too!

<img src="https://github.com/abhinishere/challo/blob/main/assets/showcase/challo-1.png" width="150"/> <img src="https://github.com/abhinishere/challo/blob/main/assets/showcase/challo-2.png" width="150"/> <img src="https://github.com/abhinishere/challo/blob/main/assets/showcase/challo-3.png" width="150"/> <img src="https://github.com/abhinishere/challo/blob/main/assets/showcase/challo-4.png" width="150"/> <img src="https://github.com/abhinishere/challo/blob/main/assets/showcase/challo-5.png" width="150"/> <img src="https://github.com/abhinishere/challo/blob/main/assets/showcase/challo-6.png" width="150"/> <img src="https://github.com/abhinishere/challo/blob/main/assets/showcase/challo-7.png" width="150"/> <img src="https://github.com/abhinishere/challo/blob/main/assets/showcase/challo-8.png" width="150"/> <img src="https://github.com/abhinishere/challo/blob/main/assets/showcase/challo-9.png" width="150"/>

Check out the app - [Play Store](https://play.google.com/store/apps/details?id=tv.challo.challo) and [App Store](https://apps.apple.com/in/app/challo-live-discussions/id1611176469)

## Getting Started

1. Start an Android and iOS project on Firebase. Note that this project requires Firebase Autentication, Cloud Firestore, Realtime Database, and Firebase Storage. Download and copy `google-services.json` to `android/app` and `GoogleService-Info.plist` to `iOS/Runner`.
2. Live streaming features including QnA (1 user), Debate (2 users), and Podcast (upto 3 users) are taken care of by Agora SDK, and so you will need to create an Agora account and start a new project. Agora also offers a cloud recording feature you can configure to have your livestreams recorded and stored on AWS. [Here is an easy guide to set this all up](https://www.agora.io/en/blog/cloud-recording-for-flutter-video-chat/).
3. Now, in `variables.dart` file, set the `tokenServerUrl` to your Heroku server Url.
4. I've stored Agora APP ID in Firestore, but please feel free to change it to wherever you feel secure. `setupinfodocs` var in `audiencepage.dart` and `participantpage.dart` deals with getting the Agora APP ID from Firestore. This APP ID is used for creating an RTC channel object.
5. Agora Cloud Recording generates multiple .ts files of the livestream, and so these have to be merged (and converted) to a single video files for later viewing. Create a new public S3 bucket (let's call it `mergedvideosbucket` for now).
6. Get the base URL of the newly created bucket (`mergedvideosbucket`) and set the `mergedBucketBaseUrl` in `variables.dart` to this value.
7. You need to deploy two APIs -- one for transcoding the video files and the other for adding an robot-based avatar for new users on the platform. You can learn how to set this up in [this repo](https://github.com/abhinishere/some-aws-apis).
8. In `variables.dart` file, add video transcoding API URL and robo avatar generator API URL to `transcodingAPIURL` and `roboAvatarAPIURL` respectively. Also, replace `roboImagesBucketBaseUrl` value with the base URL of the S3 bucket created for storing robo avatars.
9. Run `flutter pub get` to install packages and then run the project with `flutter run` or using your IDE's tools.
