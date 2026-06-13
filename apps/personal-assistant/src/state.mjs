import fs from "node:fs";
import path from "node:path";

export class DurableState {
  constructor(dir) {
    this.dir = dir;
    this.offsetFile = path.join(dir, "telegram-offset.json");
  }

  ensure() {
    fs.mkdirSync(this.dir, { recursive: true, mode: 0o700 });
  }

  readOffset() {
    try {
      return JSON.parse(fs.readFileSync(this.offsetFile, "utf8")).offset;
    } catch {
      return 0;
    }
  }

  writeOffset(offset) {
    fs.writeFileSync(this.offsetFile, JSON.stringify({ offset }, null, 2), { mode: 0o600 });
  }
}
