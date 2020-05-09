import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

Widget cachedNetworkImage(String mediaUrl) {
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    errorWidget: (context, url, error) => Icon(Icons.error),
    fit: BoxFit.cover,
    placeholder: (context, url) => Padding(
      padding: EdgeInsets.all(20.0),
      child: CircularProgressIndicator(),
    ),
  );
}
