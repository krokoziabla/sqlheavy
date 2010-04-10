namespace SQLHeavy {
  internal static bool error_if_not_ok (int ec, SQLHeavy.Queryable? queryable = null) throws SQLHeavy.Error {
    if ( ec == Sqlite.OK )
      return true;

    string? msg = (queryable != null) ? queryable.database.db.errmsg () : null;
    switch ( ec ) {
      case Sqlite.ERROR:      throw new Error.ERROR        (msg ?? SQLHeavy.ErrorMessage.ERROR);
      case Sqlite.INTERNAL:   throw new Error.INTERNAL     (msg ?? SQLHeavy.ErrorMessage.INTERNAL);
      case Sqlite.PERM:       throw new Error.ACCESS_DENIED(msg ?? SQLHeavy.ErrorMessage.ACCESS_DENIED);
      case Sqlite.ABORT:      throw new Error.ABORTED      (msg ?? SQLHeavy.ErrorMessage.ABORTED);
      case Sqlite.BUSY:       throw new Error.BUSY         (msg ?? SQLHeavy.ErrorMessage.BUSY);
      case Sqlite.LOCKED:     throw new Error.LOCKED       (msg ?? SQLHeavy.ErrorMessage.LOCKED);
      case Sqlite.NOMEM:      throw new Error.NO_MEMORY    (msg ?? SQLHeavy.ErrorMessage.NO_MEMORY);
      case Sqlite.READONLY:   throw new Error.READ_ONLY    (msg ?? SQLHeavy.ErrorMessage.READ_ONLY);
      case Sqlite.INTERRUPT:  throw new Error.INTERRUPTED  (msg ?? SQLHeavy.ErrorMessage.INTERRUPTED);
      case Sqlite.IOERR:      throw new Error.IO           (msg ?? SQLHeavy.ErrorMessage.IO);
      case Sqlite.CORRUPT:    throw new Error.CORRUPT      (msg ?? SQLHeavy.ErrorMessage.CORRUPT);
      case Sqlite.FULL:       throw new Error.FULL         (msg ?? SQLHeavy.ErrorMessage.FULL);
      case Sqlite.CANTOPEN:   throw new Error.CAN_NOT_OPEN (msg ?? SQLHeavy.ErrorMessage.CAN_NOT_OPEN);
      case Sqlite.EMPTY:      throw new Error.EMPTY        (msg ?? SQLHeavy.ErrorMessage.EMPTY);
      case Sqlite.SCHEMA:     throw new Error.SCHEMA       (msg ?? SQLHeavy.ErrorMessage.SCHEMA);
      case Sqlite.TOOBIG:     throw new Error.TOO_BIG      (msg ?? SQLHeavy.ErrorMessage.TOO_BIG);
      case Sqlite.CONSTRAINT: throw new Error.CONSTRAINT   (msg ?? SQLHeavy.ErrorMessage.CONSTRAINT);
      case Sqlite.MISMATCH:   throw new Error.MISMATCH     (msg ?? SQLHeavy.ErrorMessage.MISMATCH);
      case Sqlite.MISUSE:     throw new Error.MISUSE       (msg ?? SQLHeavy.ErrorMessage.MISUSE);
      case Sqlite.NOLFS:      throw new Error.NOLFS        (msg ?? SQLHeavy.ErrorMessage.NOLFS);
      case Sqlite.AUTH:       throw new Error.AUTH         (msg ?? SQLHeavy.ErrorMessage.AUTH);
      case Sqlite.FORMAT:     throw new Error.FORMAT       (msg ?? SQLHeavy.ErrorMessage.FORMAT);
      case Sqlite.RANGE:      throw new Error.RANGE        (msg ?? SQLHeavy.ErrorMessage.RANGE);
      case Sqlite.NOTADB:     throw new Error.NOTADB       (msg ?? SQLHeavy.ErrorMessage.NOTADB);
      case Sqlite.ROW:        throw new Error.ROW          (msg ?? SQLHeavy.ErrorMessage.ROW);
      case Sqlite.DONE:       throw new Error.DONE         (msg ?? SQLHeavy.ErrorMessage.DONE);
      default:                throw new Error.UNKNOWN      (msg ?? SQLHeavy.ErrorMessage.UNKNOWN);
    }
  }

  /**
   * SQLHeavy Errors
   *
   * Most of these are from SQLite--see [[http://sqlite.org/c3ref/c_abort.html]] for documentation.
   */
  public errordomain Error {
    /**
     * An unknown error occured
     */
    UNKNOWN,
    ERROR,
    INTERNAL,
    ACCESS_DENIED,
    ABORTED,
    BUSY,
    LOCKED,
    NO_MEMORY,
    READ_ONLY,
    INTERRUPTED,
    IO,
    CORRUPT,
    NOT_FOUND,
    FULL,
    CAN_NOT_OPEN,
    PROTOCOL,
    EMPTY,
    SCHEMA,
    TOO_BIG,
    CONSTRAINT,
    MISMATCH,
    MISUSE,
    NOLFS,
    AUTH,
    FORMAT,
    RANGE,
    NOTADB,
    ROW,
    DONE,

    /**
     * An unhandled data type was encountered.
     */
    DATA_TYPE
  }

  internal int sqlite_code_from_error (SQLHeavy.Error e) {
    if ( e is Error.INTERNAL )
      return Sqlite.INTERNAL;
    else if ( e is Error.ACCESS_DENIED )
      return Sqlite.PERM;
    else
      return Sqlite.ERROR;
      // case Sqlite.ERROR:      throw new Error.ERROR        (SQLHeavy.ErrorMessage.ERROR);
      // case Sqlite.ABORT:      throw new Error.ABORTED      (SQLHeavy.ErrorMessage.ABORTED);
      // case Sqlite.BUSY:       throw new Error.BUSY         (SQLHeavy.ErrorMessage.BUSY);
      // case Sqlite.LOCKED:     throw new Error.LOCKED       (SQLHeavy.ErrorMessage.LOCKED);
      // case Sqlite.NOMEM:      throw new Error.NO_MEMORY    (SQLHeavy.ErrorMessage.NO_MEMORY);
      // case Sqlite.READONLY:   throw new Error.READ_ONLY    (SQLHeavy.ErrorMessage.READ_ONLY);
      // case Sqlite.INTERRUPT:  throw new Error.INTERRUPTED  (SQLHeavy.ErrorMessage.INTERRUPTED);
      // case Sqlite.IOERR:      throw new Error.IO           (SQLHeavy.ErrorMessage.IO);
      // case Sqlite.CORRUPT:    throw new Error.CORRUPT      (SQLHeavy.ErrorMessage.CORRUPT);
      // case Sqlite.FULL:       throw new Error.FULL         (SQLHeavy.ErrorMessage.FULL);
      // case Sqlite.CANTOPEN:   throw new Error.CAN_NOT_OPEN (SQLHeavy.ErrorMessage.CAN_NOT_OPEN);
      // case Sqlite.EMPTY:      throw new Error.EMPTY        (SQLHeavy.ErrorMessage.EMPTY);
      // case Sqlite.SCHEMA:     throw new Error.SCHEMA       (SQLHeavy.ErrorMessage.SCHEMA);
      // case Sqlite.TOOBIG:     throw new Error.TOO_BIG      (SQLHeavy.ErrorMessage.TOO_BIG);
      // case Sqlite.CONSTRAINT: throw new Error.CONSTRAINT   (SQLHeavy.ErrorMessage.CONSTRAINT);
      // case Sqlite.MISMATCH:   throw new Error.MISMATCH     (SQLHeavy.ErrorMessage.MISMATCH);
      // case Sqlite.MISUSE:     throw new Error.MISUSE       (SQLHeavy.ErrorMessage.MISUSE);
      // case Sqlite.NOLFS:      throw new Error.NOLFS        (SQLHeavy.ErrorMessage.NOLFS);
      // case Sqlite.AUTH:       throw new Error.AUTH         (SQLHeavy.ErrorMessage.AUTH);
      // case Sqlite.FORMAT:     throw new Error.FORMAT       (SQLHeavy.ErrorMessage.FORMAT);
      // case Sqlite.RANGE:      throw new Error.RANGE        (SQLHeavy.ErrorMessage.RANGE);
      // case Sqlite.NOTADB:     throw new Error.NOTADB       (SQLHeavy.ErrorMessage.NOTADB);
      // case Sqlite.ROW:        throw new Error.ROW          (SQLHeavy.ErrorMessage.ROW);
      // case Sqlite.DONE:       throw new Error.DONE         (SQLHeavy.ErrorMessage.DONE);
      // default:                throw new Error.UNKNOWN      (SQLHeavy.ErrorMessage.UNKNOWN);
  }

  /**
   * Namespace used internally to store description of error codes.
   */
  namespace ErrorMessage {
    internal const string ERROR         = "SQL error or missing database";
    internal const string INTERNAL      = "Internal logic error in SQLite";
    internal const string ACCESS_DENIED = "Access permission denied";
    internal const string ABORTED       = "Callback routine requested an abort";
    internal const string BUSY          = "The database file is locked";
    internal const string LOCKED        = "A table in the database is locked";
    internal const string NO_MEMORY     = "A malloc failed";
    internal const string READ_ONLY     = "Attempt to write a readonly database";
    internal const string INTERRUPTED   = "Operation terminated by sqlite3_interrupt = ";
    internal const string IO            = "Some kind of disk I/O error occurred";
    internal const string CORRUPT       = "The database disk image is malformed";
    internal const string FULL          = "Insertion failed because database is full";
    internal const string CAN_NOT_OPEN  = "Unable to open the database file";
    internal const string EMPTY         = "Database is empty";
    internal const string SCHEMA        = "The database schema changed";
    internal const string TOO_BIG       = "String or BLOB exceeds size limit";
    internal const string CONSTRAINT    = "Abort due to constraint violation";
    internal const string MISMATCH      = "Data type mismatch";
    internal const string MISUSE        = "Library used incorrectly";
    internal const string NOLFS         = "Uses OS features not supported on host";
    internal const string AUTH          = "Authorization denied";
    internal const string FORMAT        = "Auxiliary database format error";
    internal const string RANGE         = "2nd parameter to sqlite3_bind out of range";
    internal const string NOTADB        = "File opened that is not a database file";
    internal const string ROW           = "sqlite3_step() has another row ready";
    internal const string DONE          = "sqlite3_step() has finished executing";
    internal const string UNKNOWN       = "Unknown error occured.";
  }
}
