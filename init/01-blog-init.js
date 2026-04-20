db = db.getSiblingDB("blog_db");

db.createCollection("posts", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["titre", "auteur", "vues"],
      additionalProperties: false,
      properties: {
        _id: {
          bsonType: "objectId"
        },
        titre: {
          bsonType: "string",
          description: "Le titre doit etre une chaine."
        },
        auteur: {
          bsonType: "string",
          description: "L'auteur doit etre une chaine."
        },
        vues: {
          bsonType: "int",
          minimum: 0,
          description: "Le nombre de vues doit etre un entier positif."
        }
      }
    }
  },
  validationAction: "error",
  validationLevel: "strict"
});

db.posts.insertMany([
  { titre: "Premier post", auteur: "Marc", vues: NumberInt(120) },
  { titre: "Docker basics", auteur: "Alice", vues: NumberInt(87) },
  { titre: "Mongo schema", auteur: "Bob", vues: NumberInt(43) },
  { titre: "Validation JSON", auteur: "Nina", vues: NumberInt(201) },
  { titre: "TP Ynov", auteur: "Lmarc", vues: NumberInt(12) }
]);

