package com.example.test.ui.semantic_recognition

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.*
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.core.content.FileProvider
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.example.test.R
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

class SemanticRecognitionFragment : Fragment() {
    // UI 元件
    private lateinit var imageView: ImageView
    private lateinit var uploadButton: Button
    private lateinit var ocrButton: Button
    private lateinit var predictButton: Button
    private lateinit var ocrResultEditText: TextView
    private lateinit var predictionResultTextView: TextView
    private lateinit var showHistoryButton: Button
    private lateinit var cameraButton: Button

    // 網絡請求客戶端
    private val client = OkHttpClient()

    // 其他屬性
    private lateinit var historyDialog: AlertDialog
    private lateinit var imagePickerLauncher: ActivityResultLauncher<Intent>
    private lateinit var cameraLauncher: ActivityResultLauncher<Intent>
    private lateinit var cameraUri: Uri
    private var selectedImageUri: Uri? = null
    private var ocrResult: String = ""

    // Fragment 生命週期方法
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        val view = inflater.inflate(R.layout.fragment_0, container, false)
        initializeViews(view)
        setupListeners()
        initHistoryDialog()
        initImagePickerLauncher()
        initCameraLauncher()
        return view
    }

    override fun onResume() {
        super.onResume()
        clearTextViews()
    }

    // 初始化視圖
    private fun initializeViews(view: View) {
        imageView = view.findViewById(R.id.image_view)
        uploadButton = view.findViewById(R.id.upload_button)
        ocrButton = view.findViewById(R.id.re_orc_button)
        predictButton = view.findViewById(R.id.predict_button)
        ocrResultEditText = view.findViewById(R.id.text_ocr)
        predictionResultTextView = view.findViewById(R.id.text_return)
        showHistoryButton = view.findViewById(R.id.show_history_button)
        cameraButton = view.findViewById(R.id.camera_button)
    }

    // 設置監聽器
    private fun setupListeners() {
        uploadButton.setOnClickListener { openGallery() }
        ocrButton.setOnClickListener { performOCR() }
        predictButton.setOnClickListener { performPrediction() }
        showHistoryButton.setOnClickListener { showHistoryDialog() }
        cameraButton.setOnClickListener { openCamera() }
    }

    private fun initImagePickerLauncher() {
        imagePickerLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            if (result.resultCode == Activity.RESULT_OK) {
                result.data?.data?.let { uri ->
                    selectedImageUri = uri
                    imageView.setImageURI(uri)
                    ocrResult = ""
                    ocrResultEditText.text = getString(R.string.ocr_empty_result)
                }
            }
        }
    }

    private fun initCameraLauncher() {
        cameraLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            if (result.resultCode == Activity.RESULT_OK) {
                imageView.setImageURI(cameraUri)
                selectedImageUri = cameraUri
                ocrResult = ""
                ocrResultEditText.text = getString(R.string.ocr_empty_result)
            }
        }
    }

    private fun clearTextViews() {
        ocrResultEditText.text = ""
        predictionResultTextView.text = ""
        ocrResult = ""
    }

    // 圖片選擇和相機相關方法
    private fun openGallery() {
        val intent = Intent(Intent.ACTION_PICK)
        intent.type = "image/*"
        imagePickerLauncher.launch(intent)
    }

    private fun openCamera() {
        val timeStamp: String = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val storageDir: File? = requireContext().getExternalFilesDir(Environment.DIRECTORY_PICTURES)
        val imageFile = File.createTempFile(
            "JPEG_${timeStamp}_",
            ".jpg",
            storageDir
        )

        cameraUri = FileProvider.getUriForFile(
            requireContext(),
            "${requireContext().packageName}.fileprovider",
            imageFile
        )

        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, cameraUri)
        }

        cameraLauncher.launch(intent)
    }

    // OCR 和預測相關方法
    private fun performOCR() {
        selectedImageUri?.let { uri ->
            try {
                val image = InputImage.fromFilePath(requireContext(), uri)
                val recognizer = TextRecognition.getClient(ChineseTextRecognizerOptions.Builder().build())

                recognizer.process(image)
                    .addOnSuccessListener { visionText ->
                        ocrResult = visionText.text
                        ocrResultEditText.text = getString(R.string.ocr_result, ocrResult)
                    }
                    .addOnFailureListener { e ->
                        ocrResultEditText.text = getString(R.string.ocr_failure, e.message)
                        ocrResult = ""
                    }
            } catch (e: IOException) {
                ocrResultEditText.text = getString(R.string.image_load_failure, e.message)
                ocrResult = ""
            }
        } ?: run {
            Toast.makeText(context, "請先選擇一張圖片", Toast.LENGTH_SHORT).show()
        }
    }

    private fun performPrediction() {
        val inputText = ocrResultEditText.text.toString().trim()
        if (inputText.isNotEmpty()) {
            ocrResult = inputText
            sendStrRequest(inputText)
        } else {
            Toast.makeText(context, "請先輸入文本或執行OCR", Toast.LENGTH_SHORT).show()
        }
    }

    // 網絡請求相關方法
    private fun sendStrRequest(text: String) {
        val ip = getString(R.string.ip)
        val port = getString(R.string.port)
        val url = "http://$ip:$port/str_request"

        val requestBody = text.toRequestBody("text/plain".toMediaTypeOrNull())
        val request = Request.Builder()
            .url(url)
            .post(requestBody)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                activity?.runOnUiThread {
                    Toast.makeText(context, getString(R.string.error_message, e.message), Toast.LENGTH_SHORT).show()
                    predictionResultTextView.text = getString(R.string.error_message, e.message)
                }
            }

            override fun onResponse(call: Call, response: Response) {
                response.body?.string()?.let { responseData ->
                    activity?.runOnUiThread {
                        predictionResultTextView.text = getString(R.string.prediction_result, responseData)
                        saveHistory(responseData)
                    }
                }
            }
        })
    }

    // 歷史記錄相關方法
    private fun initHistoryDialog() {
        val dialogView = layoutInflater.inflate(R.layout.dialog_history, null)
        val recyclerView = dialogView.findViewById<RecyclerView>(R.id.history_recycler_view)
        val closeButton = dialogView.findViewById<Button>(R.id.close_dialog_button)

        val adapter = HistoryAdapter(getHistory())
        recyclerView.adapter = adapter
        recyclerView.layoutManager = LinearLayoutManager(context)

        historyDialog = AlertDialog.Builder(requireContext())
            .setView(dialogView)
            .create()

        closeButton.setOnClickListener {
            historyDialog.dismiss()
        }
    }

    private fun showHistoryDialog() {
        (historyDialog.findViewById<RecyclerView>(R.id.history_recycler_view)?.adapter as? HistoryAdapter)?.updateData(getHistory())
        historyDialog.show()
    }

    private fun getHistory(): List<Triple<String, String, String>> {
        val sharedPref = activity?.getPreferences(Context.MODE_PRIVATE) ?: return emptyList()
        val historyJson = sharedPref.getString("semantic_search_history", "[]")
        val historyArray = JSONArray(historyJson)
        return (0 until historyArray.length()).map {
            val entry = historyArray.getJSONObject(it)
            Triple(
                entry.getString("result"),
                entry.getString("ocrText"),
                entry.getString("timestamp")
            )
        }.reversed()
    }

    private fun saveHistory(result: String) {
        val sharedPref = activity?.getPreferences(Context.MODE_PRIVATE) ?: return
        val historyJson = sharedPref.getString("semantic_search_history", "[]")
        val separator = "----------------------------------------------------------------"
        val historyArray = JSONArray(historyJson)

        val currentTime = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        val newEntry = JSONObject().apply {
            put("result", "$result\n$separator")
            put("ocrText", ocrResult)
            put("timestamp", "$separator\n$currentTime")
        }

        historyArray.put(newEntry)

        with(sharedPref.edit()) {
            putString("semantic_search_history", historyArray.toString())
            apply()
        }
    }

    // 歷史記錄適配器
    inner class HistoryAdapter(private var history: List<Triple<String, String, String>>) : RecyclerView.Adapter<HistoryAdapter.ViewHolder>() {
        inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
            val textView: TextView = view.findViewById(android.R.id.text1)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            val view = LayoutInflater.from(parent.context).inflate(android.R.layout.simple_list_item_1, parent, false)
            return ViewHolder(view)
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            val (result, ocrText, timestamp) = history[position]
            holder.textView.text = holder.itemView.context.getString(
                R.string.history_item_format_with_ocr,
                timestamp,
                ocrText,
                result
            )
            holder.itemView.setOnClickListener {
                predictionResultTextView.text = holder.itemView.context.getString(R.string.search_result, result)
                ocrResultEditText.text = ocrText
                historyDialog.dismiss()
            }
        }

        override fun getItemCount() = history.size

        fun updateData(newHistory: List<Triple<String, String, String>>) {
            val diffResult = DiffUtil.calculateDiff(object : DiffUtil.Callback() {
                override fun getOldListSize(): Int = history.size
                override fun getNewListSize(): Int = newHistory.size

                override fun areItemsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
                    return history[oldItemPosition].third == newHistory[newItemPosition].third
                }

                override fun areContentsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
                    return history[oldItemPosition] == newHistory[newItemPosition]
                }
            })

            history = newHistory
            diffResult.dispatchUpdatesTo(this)
        }
    }
}