// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_mapping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryMapping _$CategoryMappingFromJson(Map<String, dynamic> json) =>
    CategoryMapping(
      keyword: json['keyword'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      caseSensitive: json['caseSensitive'] as bool? ?? false,
      exactMatch: json['exactMatch'] as bool? ?? false,
    );

Map<String, dynamic> _$CategoryMappingToJson(CategoryMapping instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'caseSensitive': instance.caseSensitive,
      'exactMatch': instance.exactMatch,
    };

CategoryList _$CategoryListFromJson(Map<String, dynamic> json) => CategoryList(
      categories: (json['categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      subcategories: (json['subcategories'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$CategoryListToJson(CategoryList instance) =>
    <String, dynamic>{
      'categories': instance.categories,
      'subcategories': instance.subcategories,
    };
