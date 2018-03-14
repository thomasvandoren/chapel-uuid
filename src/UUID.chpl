/*
Generate and parse UUIDs.

https://tools.ietf.org/html/rfc4122
*/
module UUID {
  use Assert;
  use Random;

  proc main() throws {
    writeln(uuid4());
    writeln(parse("cafecafe-cafe-cafe-cafe-cafecafecafe"));
  }

  /* Parse 36 character string with form "cafecafe-cafe-cafe-cafe-cafecafecafe"
     and return UUID record.
   */
  proc parse(s: string): UUID throws {
    if s.length != 36 then
      throw new InvalidUUIDError("UUID string must be 36 characters and take the form: cafecafe-cafe-cafe-cafe-cafecafecafe");
    if s[9] != "-" || s[14] != "-" || s[19] != "-" || s[24] != "-" then
      throw new InvalidUUIDError("UUID string must be 36 characters and take the form: cafecafe-cafe-cafe-cafe-cafecafecafe");

    var uuidArr: [1..16] uint(8);

    const uuidIndices = (1, 3, 5, 7,
                         10, 12,
                         15, 17,
                         20, 22,
                         25, 27, 29, 31, 33, 35);
    for (i, j) in zip(1..16, uuidIndices) {
      var b1 = s[j],
        b2 = s[j+1];
      var uuidByte = hexToUint(b1, b2);
      uuidArr[i] = uuidByte;
    }

    return new UUID(uuidArr);
  }

  /* Generate version 4 UUID
   */
  proc uuid4(): UUID {
    var randStream = new RandomStream(uint(8));
    var uuidArr: [1..16] uint(8);
    randStream.fillRandom(uuidArr);

    // version 4
    uuidArr[7] = (uuidArr[7] & 0x0f) | 0x40;
    // variant 10
    uuidArr[9] = (uuidArr[9] & 0x3f) | 0x80;

    return new UUID(uuidArr);
  }

  // array to convert hex string characters to hexidecimal digit, or 255 if not a hex digit
  const hexValues = [
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 255, 255, 255, 255, 255, 255,
	255, 10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
	255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
  ];

  proc hexToUint(hex1: string, hex2: string): uint(8) throws {
    if hex1.length != 1 || hex2.length != 1 then
      throw new InvalidUUIDError("Invalid byte '%s' or '%s'".format(hex1, hex2));

    var b1 = hexValues[ ascii(hex1) + 1 ],
      b2 = hexValues[ ascii(hex2) + 1 ];

    if b1 == 255 || b2 == 255 then
      throw new InvalidUUIDError("Invalid byte");

    return ((b1 << 4) | b2): uint(8);
  }

  record UUID {
    // TODO: consider using buffer or bytes (from Buffer module)... (thomasvandoren, 2018-03-16)
    var val: [1..16] uint(8);

    proc init(existingUuid: [] uint(8)) where existingUuid.rank == 1 {
      assert(existingUuid.domain.dim(1).length == 16);
      this.val = existingUuid;
    }

    proc writeThis(writer) {
      // String form of uuid: cafecafe-cafe-cafe-cafe-cafecafecafe
      for i in 1..4 do
        // FIXME: deal with errors (thomasvandoren, 2018-03-13)
        writer <~> ( try! "%02xu".format(this.val[i]) );
      writer <~> "-";
      for i in 5..6 do
        writer <~> ( try! "%02xu".format(this.val[i]) );
      writer <~> "-";
      for i in 7..8 do
        writer <~> ( try! "%02xu".format(this.val[i]) );
      writer <~> "-";
      for i in 9..10 do
        writer <~> ( try! "%02xu".format(this.val[i]) );
      writer <~> "-";
      for i in 11..16 do
        writer <~> ( try! "%02xu".format(this.val[i]) );
    }
  }

  class InvalidUUIDError: Error {
    var msg: string;

    proc init(msg) {
      this.msg = msg;
    }

    proc writethis(writer) {
      super(writer);
      writer <~> msg;
    }
  }
}
