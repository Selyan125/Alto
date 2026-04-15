class ElementModel {
  final String key;            
  final String value;        
  final String? decryptedValue; 
  final bool isSentByMe;      

  const ElementModel({
    required this.key,
    required this.value,
    this.decryptedValue,
    this.isSentByMe = false,
  });

  // Crée depuis la réponse JSON de GET /element
  factory ElementModel.fromJson(Map<String, dynamic> json) => ElementModel(
    key:   json['key']   as String,
    value: json['value'] as String,
  );

  // Retourne une copie avec le contenu déchiffré
  ElementModel withDecrypted(String plaintext) => ElementModel(
    key:            key,
    value:          value,
    decryptedValue: plaintext,
    isSentByMe:     isSentByMe,
  );

  // Retourne une copie marquée comme "envoyé par moi"
  ElementModel asSent(String plaintext) => ElementModel(
    key:            key,
    value:          value,
    decryptedValue: plaintext,
    isSentByMe:     true,
  );
}

enum ElementType { message, icon, color, url, location }

String elementTypeToString(ElementType t) {
  switch (t) {
    case ElementType.icon:     return 'ICON';
    case ElementType.color:    return 'COLOR';
    case ElementType.url:      return 'URL';
    case ElementType.location: return 'LOCATION';
    default:                   return 'MESSAGE';
  }
}

ElementType elementTypeFromString(String s) {
  switch (s.toUpperCase()) {
    case 'ICON':     return ElementType.icon;
    case 'COLOR':    return ElementType.color;
    case 'URL':      return ElementType.url;
    case 'LOCATION': return ElementType.location;
    default:         return ElementType.message;
  }
}