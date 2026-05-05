const generateRequestNumber = async (db) => {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const prefix = `PRQ-${year}${month}-`;

    const [rows] = await db.query(
        `SELECT request_number FROM procurement_requests 
         WHERE request_number LIKE ? 
         ORDER BY id DESC LIMIT 1`,
        [`${prefix}%`]
    );

    let nextNumber = 1;
    if (rows.length > 0) {
        const lastNumberStr = rows[0].request_number.split('-')[2];
        nextNumber = parseInt(lastNumberStr, 10) + 1;
    }

    const paddedNumber = String(nextNumber).padStart(4, '0');
    return `${prefix}${paddedNumber}`;
};

module.exports = { generateRequestNumber };
