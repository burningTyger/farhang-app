const send = require('@polka/send');
const db = require('better-sqlite3')('farhang.db');
db.loadExtension('./libicu.so');

const Trouter = require('trouter');
const router = new Trouter();
router.get('/a/:term', req => db
  .prepare('SELECT id, lemma FROM lemmas WHERE lemma LIKE ? ORDER BY lemma ')
  .all(req.params.term + '%')
);
router.get('/g/:id', req => db
  .prepare('SELECT source, target FROM translations WHERE lemma_id = ?')
  .all(req.params.id)
);

function next(err) {
	if (err) throw err;
}

async function loop (arr, req, res) {
	let fn, out;
	for (fn of arr) {
		out = await fn(req, res, next) || out;
	}
	return out;
}

module.exports = async function (req, res) {
	let obj = router.find(req.method, req.url);
	if (!obj) return send(res, 404, 'Not found');

	try {
    req.params = obj.params;
    return await loop(obj.handlers, req, res);
	} catch (err) {
		send(res, err.statusCode || 400, err.message || err);
	}
}
