namespace SQLHeavy {
  [CCode (cname = "sqlite3_open_v2", cheader_filename = "sqlite3.h")]
  private extern static int sqlite3_open (string filename, out unowned Sqlite.Database db, int flags = Sqlite.OPEN_READWRITE | Sqlite.OPEN_CREATE, string? zVfs = null);
  [CCode (cname = "sqlite3_close", cheader_filename = "sqlite3.h")]
  private extern static int sqlite3_close (Sqlite.Database db);

  /**
   * A database.
   */
  public class Database : Queryable {
    private GLib.HashTable <string, UserFunction.UserFuncData> user_functions =
      new GLib.HashTable <string, UserFunction.UserFuncData>.full (GLib.str_hash, GLib.str_equal, GLib.g_free, GLib.g_object_unref);
    internal unowned Sqlite.Database db;

    private SQLHeavy.Statement? profiling_insert_stmt = null;
    public void profiling_cb (string sql, uint64 time) {
      try {
        if ( this.profiling_insert_stmt == null )
          this.profiling_insert_stmt = this.profiling_data.prepare ("INSERT INTO `queries` (`sql`, `clock`) VALUES (:sql, :clock);");

        unowned SQLHeavy.Statement stmt = this.profiling_insert_stmt;
        stmt.auto_clear = true;
        stmt.bind_named_string (":sql", sql);
        stmt.bind_named_int64 (":clock", (int64)time);
        stmt.execute ();
        stmt.reset ();
      }
      catch ( SQLHeavy.Error e ) {
        GLib.warning ("Unable to insert profiling information: %s (%d)", e.message, e.code);
      }
    }

    /**
     * Database to store profiling data in.
     */
    public SQLHeavy.Database? profiling_data = null;

    /**
     * Whether profiling is enabled.
     */
    public bool enable_profiling {
      get { return this.profiling_data != null; }
      set {
        this.profiling_insert_stmt = null;

        if ( value == false ) {
          this.profiling_data = null;
          this.db.profile (null);
        }
        else {
          try {
            if ( this.profiling_data == null )
              this.profiling_data = new SQLHeavy.Database ();

            this.profiling_data.execute ("""
CREATE TABLE IF NOT EXISTS `queries` (
  `sql` TEXT UNIQUE NOT NULL,
  `executions` INTEGER DEFAULT 1,
  `clock` INTEGER UNSIGNED NOT NULL
);

CREATE TRIGGER IF NOT EXISTS `queries_insert`
  BEFORE INSERT ON `queries`
  WHEN (SELECT COUNT(*) FROM `queries` WHERE `sql` = NEW.`sql`) > 0
  BEGIN
    UPDATE `queries`
      SET
        `executions` = `executions` + 1,
        `clock` = `clock` + NEW.`clock`
      WHERE `sql` = NEW.`sql`;
    SELECT RAISE(IGNORE);
  END;""");
          }
          catch ( SQLHeavy.Error e ) {
            GLib.warning ("Unable to enable profiling: %s (%d)", e.message, e.code);
            return;
          }

          this.db.profile (this.profiling_cb);
        }
      }
    }

    public string filename { get; construct; default = ":memory:"; }
    public SQLHeavy.FileMode mode {
      get;
      construct;
      default = SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE | SQLHeavy.FileMode.CREATE;
    }

    public int64 last_insert_id { get { return this.db.last_insert_rowid (); } }

    private string? pragma_get_string (string pragma) {
      try {
        var stmt = new SQLHeavy.Statement (this, "PRAGMA %s;".printf (pragma));
        stmt.step ();
        return stmt.fetch_string (0);
      }
      catch ( SQLHeavy.Error e ) {
        GLib.critical ("Unable to retrieve pragma value: %s", e.message);
        return null;
      }
    }

    private int pragma_get_int (string pragma) {
      return this.pragma_get_string (pragma).to_int ();
    }

    private bool pragma_get_bool (string pragma) {
      return this.pragma_get_int (pragma) != 0;
    }

    private void pragma_set_string (string pragma, string value) {
      try {
        var stmt = new SQLHeavy.Statement (this, "PRAGMA %s = %s;".printf (pragma, value));
        stmt.execute ();
      }
      catch ( SQLHeavy.Error e ) {
        GLib.critical ("Unable to retrieve pragma value: %s", e.message);
      }
    }

    private void pragma_set_int (string pragma, int value) {
      this.pragma_set_string (pragma, "%d".printf(value));
    }

    private void pragma_set_bool (string pragma, bool value) {
      this.pragma_set_int (pragma, value ? 1 : 0);
    }

    /**
     * Auto-Vacuum mode
     */
    public SQLHeavy.AutoVacuum auto_vacuum {
      get { return (SQLHeavy.AutoVacuum) this.pragma_get_int("auto_vacuum"); }
      set { this.pragma_set_int ("auto_vacuum", value); }
    }

    /**
     * Cache size
     */
    public int cache_size {
      get { return this.pragma_get_int ("cache_size"); }
      set { this.pragma_set_int ("cache_size", value); }
    }

    public bool case_sensitive_like {
      get { return this.pragma_get_bool ("case_sensitive_like"); }
      set { this.pragma_set_bool ("case_sensitive_like", value); }
    }

    public bool count_changes {
      get { return this.pragma_get_bool ("count_changes"); }
      set { this.pragma_set_bool ("count_changes", value); }
    }

    public int default_cache_size {
      get { return this.pragma_get_int ("default_cache_size"); }
      set { this.pragma_set_int ("default_cache_size", value); }
    }

    public bool empty_result_callbacks {
      get { return this.pragma_get_bool ("empty_result_callbacks"); }
      set { this.pragma_set_bool ("empty_result_callbacks", value); }
    }

    public SQLHeavy.Encoding encoding {
      get { return SQLHeavy.Encoding.from_string (this.pragma_get_string ("encoding")); }
      set { this.pragma_set_string ("encoding", value.to_string ()); }
    }

    public bool foreign_keys {
      get { return this.pragma_get_bool ("foreign_keys"); }
      set { this.pragma_set_bool ("foreign_keys", value); }
    }

    public bool full_column_names {
      get { return this.pragma_get_bool ("full_column_names"); }
      set { this.pragma_set_bool ("full_column_names", value); }
    }

    public bool full_fsync {
      get { return this.pragma_get_bool ("fullfsync"); }
      set { this.pragma_set_bool ("fullfsync", value); }
    }

    public void incremental_vacuum (int pages) {
      try {
        this.execute ("PRAGMA incremental_vacuum(%d);".printf(pages));
      }
      catch ( SQLHeavy.Error e ) {
        GLib.critical ("Unable to run incremental vacuum: %s", e.message);
      }
    }

    public SQLHeavy.JournalMode journal_mode {
      get { return SQLHeavy.JournalMode.from_string (this.pragma_get_string ("journal_mode")); }
      set { this.pragma_set_string ("journal_mode", value.to_string ()); }
    }

    public int journal_size_limit {
      get { return this.pragma_get_int ("journal_size_limit"); }
      set { this.pragma_set_int ("journal_size_limit", value); }
    }

    public bool legacy_file_format {
      get { return this.pragma_get_bool ("legacy_file_format"); }
      set { this.pragma_set_bool ("legacy_file_format", value); }
    }

    public SQLHeavy.LockingMode locking_mode {
      get { return SQLHeavy.LockingMode.from_string (this.pragma_get_string ("locking_mode")); }
      set { this.pragma_set_string ("locking_mode", value.to_string ()); }
    }

    public int page_size {
      get { return this.pragma_get_int ("page_size"); }
      set {
        if ( (value & (value - 1)) != 0 )
          GLib.critical ("Page size must be a power of two.");
        this.pragma_set_int ("page_size", value);
      }
    }

    public int max_page_count {
      get { return this.pragma_get_int ("max_page_count"); }
      set { this.pragma_set_int ("max_page_count", value); }
    }

    public bool read_uncommitted {
      get { return this.pragma_get_bool ("read_uncommitted"); }
      set { this.pragma_set_bool ("read_uncommitted", value); }
    }

    public bool recursive_triggers {
      get { return this.pragma_get_bool ("recursive_triggers"); }
      set { this.pragma_set_bool ("recursive_triggers", value); }
    }

    public bool reverse_unordered_selects {
      get { return this.pragma_get_bool ("reverse_unordered_selects"); }
      set { this.pragma_set_bool ("reverse_unordered_selects", value); }
    }

    public bool short_column_names {
      get { return this.pragma_get_bool ("short_column_names"); }
      set { this.pragma_set_bool ("short_column_names", value); }
    }

    public SQLHeavy.SynchronousMode synchronous {
      get { return SQLHeavy.SynchronousMode.from_string (this.pragma_get_string ("synchronous")); }
      set { this.pragma_set_string ("synchronous", value.to_string ()); }
    }

    public SQLHeavy.TempStoreMode temp_store {
      get { return SQLHeavy.TempStoreMode.from_string (this.pragma_get_string ("temp_store")); }
      set { this.pragma_set_string ("temp_store", value.to_string ()); }
    }

    public string temp_store_directory {
      owned get { return this.pragma_get_string ("temp_store_directory"); }
      set { this.pragma_set_string ("temp_store_directory", value); }
    }

    //public GLib.SList<string> collation_list { get; }
    //public ?? database_list { get; }
    //public ?? get_foreign_key_list (string table_name);

    public int free_list_count {
      get { return this.pragma_get_int ("freelist_count"); }
      set { this.pragma_set_int ("freelist_count", value); }
    }

    //public ?? get_index_info (string index_name);
    //public ?? get_index_list (string table_name);

    public int page_count {
      get { return this.pragma_get_int ("page_count"); }
      set { this.pragma_set_int ("page_count", value); }
    }

    //public ?? get_table_info (string table_name);

    public int schema_version {
      get { return this.pragma_get_int ("schema_version"); }
      set { this.pragma_set_int ("schema_version", value); }
    }

    public int user_version {
      get { return this.pragma_get_int ("user_version"); }
      set { this.pragma_set_int ("user_version", value); }
    }

    //public GLib.SList<string> integrity_check (int max_errors = 100);
    //public GLib.SList<string> quick_check (int max_errors = 100);

    public bool parser_trace {
      get { return this.pragma_get_bool ("parser_trace"); }
      set { this.pragma_set_bool ("parser_trace", value); }
    }

    public bool vdbe_trace {
      get { return this.pragma_get_bool ("vdbe_trace"); }
      set { this.pragma_set_bool ("vdbe_trace", value); }
    }

    public bool vdbe_listing {
      get { return this.pragma_get_bool ("vdbe_listing"); }
      set { this.pragma_set_bool ("vdbe_listing", value); }
    }

    construct {
      if ( this.filename != ":memory:" ) {
        string dirname = GLib.Path.get_dirname (filename);
        if ( !GLib.FileUtils.test (dirname, GLib.FileTest.EXISTS) )
          GLib.DirUtils.create_with_parents (dirname, 0700);
      }

      int flags = 0;
      if ( (this.mode & SQLHeavy.FileMode.READ) == SQLHeavy.FileMode.READ )
        flags = Sqlite.OPEN_READONLY;
      if ( (this.mode & SQLHeavy.FileMode.WRITE) == SQLHeavy.FileMode.WRITE )
        flags = Sqlite.OPEN_READWRITE;
      if ( (this.mode & SQLHeavy.FileMode.CREATE) == SQLHeavy.FileMode.CREATE )
        flags |= Sqlite.OPEN_CREATE;

      if ( sqlite3_open ((!) filename, out this.db, flags, null) != Sqlite.OK ) {
        this.db = null;
        GLib.critical ("Unable to open database.");
      }
    }

    public void register_aggregate_function (string name,
                                             int argc,
                                             owned UserFunction.UserFunc func,
                                             owned UserFunction.FinalizeFunc final) {
      this.unregister_function (name);
      var ufc = new UserFunction.UserFuncData.scalar (this, name, argc, func);
      this.user_functions.insert (name, ufc);
      this.db.create_function (name, argc, Sqlite.UTF8, ufc, null,
                               UserFunction.on_user_function_called,
                               UserFunction.on_user_finalize_called);
    }

    public void register_scalar_function (string name,
                                          int argc,
                                          owned UserFunction.UserFunc func) {
      this.unregister_function (name);
      var ufc = new UserFunction.UserFuncData.scalar (this, name, argc, func);
      this.user_functions.insert (name, ufc);
      this.db.create_function (name, argc, Sqlite.UTF8, ufc, UserFunction.on_user_function_called, null, null);
    }

    private void unregister_function_context (UserFunction.UserFuncData ufc) {
      this.db.create_function (ufc.name, ufc.argc, Sqlite.UTF8, ufc, null, null, null);
    }

    public void unregister_function (string name) {
      var ufc = this.user_functions.lookup (name);
      if ( ufc != null )
        this.unregister_function_context (ufc);
    }

    /**
     * Open a database.
     *
     * @param filename, Where to store the database, or null for memory only.
     * @param mode, Bitmask of mode to use when opening the database.
     */
    public Database (string? filename = null,
                     SQLHeavy.FileMode mode =
                       SQLHeavy.FileMode.READ |
                       SQLHeavy.FileMode.WRITE |
                       SQLHeavy.FileMode.CREATE) throws SQLHeavy.Error {
      if ( filename == null ) filename = ":memory:";
      Object (filename: filename, mode: mode);
    }

    ~ Database () {
      foreach ( unowned UserFunction.UserFuncData udf in this.user_functions.get_values () )
        this.unregister_function_context (udf);

      if ( this.db != null )
        sqlite3_close (this.db);
    }
  }
}
