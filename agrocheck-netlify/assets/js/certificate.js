// Generación de PDF de constancia (jsPDF)
window.generateCertificate = async function(cert) {
  const { jsPDF } = window.jspdf;
  const doc = new jsPDF({ unit: "pt", format: "A4" });
  const pageW = doc.internal.pageSize.getWidth();

  // Encabezado
  doc.setFont("helvetica", "bold");
  doc.setFontSize(18);
  doc.text("Constancia de Aprobación de Calidad y Documentación", pageW/2, 60, { align: "center" });

  // Logos (opcional): si existe un <img id="logo-img">, lo intentamos agregar
  try {
    const img = document.getElementById("logo-img");
    if (img && img.naturalWidth > 0) {
      // Convertir a data URL dibujando en canvas
      const canvas = document.createElement("canvas");
      canvas.width = img.naturalWidth;
      canvas.height = img.naturalHeight;
      const ctx = canvas.getContext("2d");
      ctx.drawImage(img, 0, 0);
      const dataURL = canvas.toDataURL("image/png");
      doc.addImage(dataURL, "PNG", 40, 40, 60, 60);
    }
  } catch (e) {}

  doc.setFont("helvetica", "normal");
  doc.setFontSize(12);

  const line = (y, label, value) => {
    doc.setFont("helvetica", "bold"); doc.text(label, 60, y);
    doc.setFont("helvetica", "normal"); doc.text(String(value ?? ""), 220, y);
  };

  let y = 120;
  line(y, "Empresa:", cert.empresa); y += 22;
  line(y, "RUC:", cert.ruc); y += 22;
  line(y, "Producto:", cert.producto); y += 22;
  line(y, "Variedad:", cert.variedad); y += 22;
  line(y, "Lote:", cert.lote); y += 22;
  line(y, "Origen:", cert.origen); y += 22;
  line(y, "Destino:", cert.destino); y += 22;
  line(y, "Fecha:", cert.fecha); y += 22;
  line(y, "Estado:", cert.estado ? "APROBADO" : "RECHAZADO"); y += 30;

  doc.setFont("helvetica", "bold");
  doc.text("Observaciones:", 60, y);
  doc.setFont("helvetica", "normal");
  const obs = doc.splitTextToSize(cert.observaciones || "Sin observaciones", pageW - 120);
  doc.text(obs, 60, y + 18);

  // Pie
  doc.setFont("helvetica", "italic");
  doc.setFontSize(10);
  doc.text("Documento generado por AgroCheck.", 60, 780);

  const file = `Constancia_${(cert.lote || "lote").replace(/\W+/g,"_")}.pdf`;
  doc.save(file);
};
