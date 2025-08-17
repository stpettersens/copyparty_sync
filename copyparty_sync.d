import std.file;
import std.path;
import std.conv;
import std.stdio;
import std.string;
import std.process;
import std.algorithm;

struct copyparty_server {
	string username;
	string password;
	string proto;
	string domain;
	string want_format;
    bool none;
}

struct file_matches {
	string file_pattern;
	string target_dir;
    string listen_for_text;
    bool none;
}

int upload_file_to_copyparty(bool verbose, copyparty_server* s, string dir, string file) {
    string endpoint = format("%s://%s/%s/", s.proto, s.domain, dir);
	string curl_switch = " ";

	version(Windows) {
		curl_switch = " -k";
	}

    string request1 = format("curl%s -s -I %s%s --user %s:%s",
    curl_switch,
    endpoint,
    file,
    s.username,
    s.password);

    auto exists = executeShell(request1);

    if (verbose) {
        writefln(request1);
        writeln(exists.output);
    }

    if (exists.status != 0) {
        writefln("Failed to check existence of remote file: '%s'.", file);
        return -1;
    }

    // If the file exists, delete it first
    // before uploading the replacement file.
    if (canFind(strip(exists.output), "OK")) {
        string request2 = format("curl%s -s -X DELETE %s%s --user %s:%s",
        curl_switch,
        endpoint,
        file,
        s.username,
        s.password);

        auto _delete = executeShell(request2);

        if (verbose) {
            writeln(request2);
            writeln(_delete.output);
        }

        if (_delete.status != 0) {
            writefln("Failed to delete remote file: '%s'.", file);
            return -1;
        }
    }

	string request3 = format("curl%s -s -u %s:%s -F f=@%s %s",
	curl_switch,
	s.username,
	s.password,
	file,
	endpoint);

    request3 ~= format("?want=%s", s.want_format);
    request3 ~= " | jq .status";

	auto upload = executeShell(request3);

    if (verbose)
        writeln(request3);

	if (upload.status != 0) {
		writefln("Failed to upload file: '%s'.", file);
        writefln("Server status: %s", upload.output);
		return -1;
	}

	writefln("Uploaded file: '%s'.", file);
    writefln("Server status: %s", upload.output);
	return 0;
}

copyparty_server read_server_cfg() {
	copyparty_server s;
	string cfg = buildPath(getcwd(), "copyparty_sync_server.cfg");
	if (cfg.exists) {
		auto f = File(cfg);
		foreach (line; f.byLine()) {
			string l = to!string(line);
			if (l.startsWith("#")) {
				// Ignore any comment lines.
				continue;
			}

			if (s.username.length == 0)
				s.username = to!string(l);

			else if (s.password.length == 0)
				s.password = to!string(l);

			else if (s.proto.length == 0)
				s.proto = to!string(l);

			else if (s.domain.length == 0)
				s.domain = to!string(l);

			else if (s.want_format.length == 0)
				s.want_format = to!string(l).toLower();
		}

        s.none = false;
		return s;
	}

    writeln("Aborting, there is no server configuration to use.");
    s.none = true;
    return s;
}

file_matches read_matches_cfg() {
	file_matches m;
	string cfg = buildPath(getcwd(), "copyparty_sync_matches.cfg");
	if (cfg.exists) {
		auto f = File(cfg);
		foreach (line; f.byLine()) {
			string l = to!string(line);
			if (l.startsWith("#")) {
				// Ignore any comment lines.
				continue;
			}

			if (m.file_pattern.length == 0)
				m.file_pattern = to!string(l);

            else if (m.target_dir.length == 0)
                m.target_dir = to!string(l);

            else if (m.listen_for_text.length == 0)
                m.listen_for_text = to!string(l);

		}

        m.none = false;
		return m;
	}

    writeln("Aborting, there is no matches configuration to use.");
    m.none = true;
    return m;
}

int main() {
	int status = 0;
    bool verbose = false;

    // There is a known problem when running this
    // program under Zellij. If Zellij instance is detected,
    // exit this program.
    string in_zellij = environment.get("ZELLIJ");
    if (strip(in_zellij) == "0") {
        writeln("Copyparty_sync cannot be run under Zellij.");
        writeln("Aborting now...");
        return -1;
    }

    copyparty_server server_cfg = read_server_cfg();
    if (server_cfg.none)
        return -1;

    file_matches matches_cfg = read_matches_cfg();
    if (matches_cfg.none)
        return -1;

    string[] patterns = matches_cfg.file_pattern.split(",");
    string dir = matches_cfg.target_dir;
    writefln("Uploading file(s) to '%s'.", dir);
    writeln("Uploading file(s) which match patterns: ", patterns);
    writeln();
    foreach (p; patterns) {
        auto _matches = dirEntries(getcwd(), p, SpanMode.depth);
        foreach (file; _matches) {
            status = upload_file_to_copyparty
            (verbose, &server_cfg, dir, baseName(file));
        }
    }

	return status;
}
