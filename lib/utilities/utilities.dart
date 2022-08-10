import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tapkat/models/product.dart';
import 'package:tapkat/utilities/constant_colors.dart';
import 'package:tapkat/utilities/size_config.dart';
import 'package:tapkat/widgets/custom_button.dart';

Future<bool?> onQuickBuy(
    BuildContext context, ProductModel product1, ProductModel product2) async {
  print('--quickbuy-product1--> ${product1.toJson()}');
  print('--quickbuy-product2--> ${product2.toJson()}');
  final result = await showDialog(
    context: context,
    builder: (dContext) {
      var thumbnail1 = '';
      var thumbnail2 = '';

      if (product1.media != null && product1.media!.isNotEmpty) {
        for (var media in product1.media!) {
          thumbnail1 = media.url_t ?? '';
          if (thumbnail1.isNotEmpty) break;
        }
      }

      if (thumbnail1.isEmpty) {
        if (product1.mediaPrimary != null &&
            product1.mediaPrimary!.url_t != null &&
            product1.mediaPrimary!.url_t!.isNotEmpty)
          thumbnail1 = product1.mediaPrimary!.url_t!;
      }

      if (product2.media != null && product2.media!.isNotEmpty) {
        for (var media in product2.media!) {
          thumbnail2 = media.url_t ?? '';
          if (thumbnail2.isNotEmpty) break;
        }
      }

      if (thumbnail2.isEmpty) {
        if (product2.mediaPrimary != null &&
            product2.mediaPrimary!.url_t != null &&
            product2.mediaPrimary!.url_t!.isNotEmpty)
          thumbnail2 = product2.mediaPrimary!.url_t!;
      }
      return Dialog(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: EdgeInsets.all(10.0),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quick Barter',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: kBackgroundColor,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      image: DecorationImage(
                        image: thumbnail1.isNotEmpty
                            ? NetworkImage(thumbnail1)
                            : AssetImage('assets/images/image_placeholder.jpg')
                                as ImageProvider<Object>,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10.0, 17.0, 10.0, 0.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.sync_alt_outlined,
                        size: SizeConfig.textScaleFactor * 15,
                        color: kBackgroundColor,
                      ),
                    ),
                  ),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: kBackgroundColor,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      image: DecorationImage(
                        image: thumbnail2.isNotEmpty
                            ? NetworkImage(thumbnail2)
                            : AssetImage('assets/images/image_placeholder.jpg')
                                as ImageProvider<Object>,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              Center(
                child: Text(
                  'Do you want to submit an offer to exchange ${product1.display_name}\'s ${product1.productname} for your ${product2.productname}?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              CustomButton(
                bgColor: kBackgroundColor,
                label: 'Yes, I want to submit the offer now',
                onTap: () {
                  Navigator.pop(dContext, true);
                },
              ),
              CustomButton(
                bgColor: kDangerColor,
                label: 'I want to edit the products to be bartered',
                onTap: () => Navigator.pop(dContext, false),
              ),
              CustomButton(
                bgColor: Colors.red.shade400,
                label: 'Cancel',
                onTap: () => Navigator.pop(dContext, null),
              ),
            ],
          ),
        ),
      );
    },
  );

  return result;
}
