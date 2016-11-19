package agersant.polaris.activity.browse;

import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.Menu;
import android.view.MenuInflater;

import com.android.volley.Response;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Stack;

import agersant.polaris.R;
import agersant.polaris.activity.PolarisActivity;
import agersant.polaris.api.ServerAPI;

public class BrowseActivity extends PolarisActivity {

    private ExplorerAdapter adapter;
    private Stack<JSONArray> history;

    BrowseActivity() {
        super(R.string.collection);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_browse);
        super.onCreate(savedInstanceState);

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        recyclerView.setLayoutManager(linearLayoutManager);

        adapter = new ExplorerAdapter(this);
        recyclerView.setAdapter(adapter);

        history = new Stack<>();
        browseTo("");
    }

    @Override
    public void onBackPressed() {
        if (history.size() < 2) {
            super.onBackPressed();
            overridePendingTransition(0, 0);
        } else {
            history.pop();
            setContent(history.peek());
        }
    }

    void browseTo(String path) {
        Response.Listener<JSONArray> success = new Response.Listener<JSONArray>() {
            @Override
            public void onResponse(JSONArray response) {
                history.push(response);
                setContent(response);
            }
        };

        ServerAPI server = ServerAPI.getInstance(getApplicationContext());
        server.browse(path, success);
    }

    private void setContent(JSONArray content) {
        ArrayList<ExplorerItem> newItems = new ArrayList<>();
        for (int i = 0; i < content.length(); i++) {
            try {
                JSONObject item = content.getJSONObject(i);
                boolean isDirectory = item.getString("variant").equals("Directory");
                JSONObject fields = item.getJSONArray("fields").getJSONObject(0);
                String name = fields.getString("path");
                ExplorerItem explorerItem = new ExplorerItem(name, isDirectory);
                newItems.add(explorerItem);
            } catch (Exception e) {
                System.err.println("Unexpected response structure");
            }
        }
        adapter.setItems(newItems);
    }
}
