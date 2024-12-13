package com.example.test.ui.url_search

import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import android.widget.EditText
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.appcompat.app.AlertDialog
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import android.view.inputmethod.InputMethodManager
import com.example.test.R
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

class UrlSearchFragment : Fragment() {
    // UI 元件
    private lateinit var urlTextbox: EditText
    private lateinit var searchUrlButton: Button
    private lateinit var textUrlReturn: TextView
    private lateinit var showHistoryButton: Button

    // 歷史記錄相關
    private lateinit var historyDialog: AlertDialog
    private lateinit var historyAdapter: HistoryAdapter

    // 網絡請求客戶端
    private val client = OkHttpClient()

    // Fragment 生命週期方法
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        val view = inflater.inflate(R.layout.fragment_2, container, false)

        initializeViews(view)
        setupListeners()
        initHistoryDialog()

        return view
    }

    override fun onResume() {
        super.onResume()
        clearTextViews()
    }

    // 初始化視圖
    private fun initializeViews(view: View) {
        urlTextbox = view.findViewById(R.id.url_textbox)
        searchUrlButton = view.findViewById(R.id.search_url_button)
        textUrlReturn = view.findViewById(R.id.text_url_return)
        showHistoryButton = view.findViewById(R.id.show_history_button)
    }

    // 設置監聽器
    private fun setupListeners() {
        searchUrlButton.setOnClickListener {
            val url = urlTextbox.text.toString()
            if (url.isNotEmpty()) {
                searchURL(url)
                hideKeyboard()
            } else {
                Toast.makeText(context, "請輸入 URL", Toast.LENGTH_SHORT).show()
            }
        }

        showHistoryButton.setOnClickListener {
            showHistoryDialog()
        }
    }

    // 清空文本視圖
    private fun clearTextViews() {
        urlTextbox.text.clear()
        textUrlReturn.text = ""
    }

    // 隱藏鍵盤
    private fun hideKeyboard() {
        val imm = context?.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.hideSoftInputFromWindow(view?.windowToken, 0)
    }

    // URL 搜索功能
    private fun searchURL(urlText: String) {
        val ip = getString(R.string.ip)
        val port = getString(R.string.port)
        val url = "http://$ip:$port/url_request"

        val requestBody = urlText.toRequestBody("text/plain".toMediaTypeOrNull())
        val request = Request.Builder()
            .url(url)
            .post(requestBody)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                activity?.runOnUiThread {
                    Toast.makeText(context, getString(R.string.error_message, e.message), Toast.LENGTH_SHORT).show()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                response.body?.string()?.let { responseData ->
                    activity?.runOnUiThread {
                        textUrlReturn.text = getString(R.string.search_result, responseData)
                        saveHistory(responseData)
                        updateHistoryAdapter()
                    }
                }
            }
        })
    }

    // 歷史記錄相關方法
    private fun saveHistory(result: String) {
        val sharedPref = activity?.getPreferences(Context.MODE_PRIVATE) ?: return
        val historyJson = sharedPref.getString("url_search_history", "[]")
        val historyArray = JSONArray(historyJson)

        val currentTime = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        val newEntry = JSONObject().apply {
            put("result", result)
            put("timestamp", currentTime)
        }

        historyArray.put(newEntry)

        with(sharedPref.edit()) {
            putString("url_search_history", historyArray.toString())
            apply()
        }
    }

    private fun initHistoryDialog() {
        val dialogView = layoutInflater.inflate(R.layout.dialog_history, null)
        val recyclerView = dialogView.findViewById<RecyclerView>(R.id.history_recycler_view)
        val closeButton = dialogView.findViewById<Button>(R.id.close_dialog_button)

        historyAdapter = HistoryAdapter(getHistory())
        recyclerView.adapter = historyAdapter
        recyclerView.layoutManager = LinearLayoutManager(context)

        historyDialog = AlertDialog.Builder(requireContext())
            .setView(dialogView)
            .create()

        closeButton.setOnClickListener {
            historyDialog.dismiss()
        }
    }

    private fun showHistoryDialog() {
        updateHistoryAdapter()
        historyDialog.show()
    }

    private fun getHistory(): List<Pair<String, String>> {
        val sharedPref = activity?.getPreferences(Context.MODE_PRIVATE) ?: return emptyList()
        val historyJson = sharedPref.getString("url_search_history", "[]")
        val historyArray = JSONArray(historyJson)
        return (0 until historyArray.length()).map {
            val entry = historyArray.getJSONObject(it)
            entry.getString("result") to entry.getString("timestamp")
        }.reversed()
    }

    private fun updateHistoryAdapter() {
        val updatedHistory = getHistory()
        historyAdapter.updateData(updatedHistory)
    }

    // 歷史記錄適配器
    inner class HistoryAdapter(private var history: List<Pair<String, String>>) : RecyclerView.Adapter<HistoryAdapter.ViewHolder>() {
        inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
            val textView: TextView = view.findViewById(android.R.id.text1)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            val view = LayoutInflater.from(parent.context).inflate(android.R.layout.simple_list_item_1, parent, false)
            return ViewHolder(view)
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            val (result, timestamp) = history[position]
            holder.textView.text = holder.itemView.context.getString(R.string.history_item_format, timestamp, result)
            holder.itemView.setOnClickListener {
                textUrlReturn.text = holder.itemView.context.getString(R.string.search_result, result)
                historyDialog.dismiss()
            }
        }

        override fun getItemCount() = history.size

        fun updateData(newHistory: List<Pair<String, String>>) {
            val diffResult = DiffUtil.calculateDiff(object : DiffUtil.Callback() {
                override fun getOldListSize(): Int = history.size
                override fun getNewListSize(): Int = newHistory.size

                override fun areItemsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
                    return history[oldItemPosition].second == newHistory[newItemPosition].second
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