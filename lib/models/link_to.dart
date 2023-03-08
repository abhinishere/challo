class LinkTo {
  String? docName;
  String? type;
  String? topic;
  String? description;
  String? image;

  LinkTo({
    this.docName,
    this.type,
    this.topic,
    this.description,
    this.image,
  });

  /*LinkTo.fromSnapshot(DocumentSnapshot snapshot, String imageFieldName) {
    docName = snapshot['docName'] ?? "";
    type = snapshot['type'] ?? "";
    topic = snapshot['topic'] ?? "";
    description = snapshot['description'] ?? "";
    image = (imageFieldName == 'imageslist')
        ? List.from((snapshot as Map)[imageFieldName][0])
        : snapshot[imageFieldName] ?? "";
  }*/
}
