import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/cupertino.dart';
import 'package:polaris/collection/interface.dart' as collection;
import 'package:polaris/ui/utils/fallback_artwork.dart';

final getIt = GetIt.instance;

class Thumbnail extends StatefulWidget {
  final String path;

  Thumbnail(this.path, {Key key}) : super(key: key);

  @override
  _ThumbnailState createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  Future<ImageProvider> _imageProvider;

  @override
  void initState() {
    super.initState();
    final interface = getIt<collection.Interface>();
    _imageProvider = interface.getImage(widget.path);
  }

  @override
  void didUpdateWidget(Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final interface = getIt<collection.Interface>();
    if (oldWidget.path != widget.path) {
      setState(() {
        _imageProvider = interface.getImage(widget.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _imageProvider,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        }
        if (_imageProvider == null || snapshot.hasError || snapshot.data == null) {
          return FallbackArtwork();
        }
        assert(snapshot.hasData);
        return Image(
          image: snapshot.data,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class LargeThumbnail extends StatelessWidget {
  final String path;

  LargeThumbnail(this.path, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Thumbnail(path),
      ),
    );
  }
}

class ListThumbnail extends StatelessWidget {
  final String path;

  ListThumbnail(this.path, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Thumbnail(path),
      ),
    );
  }
}
